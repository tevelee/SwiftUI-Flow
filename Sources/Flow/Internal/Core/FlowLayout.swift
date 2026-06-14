import CoreFoundation
import SwiftUI

/// The axis-agnostic engine behind ``HFlow`` and ``VFlow``.
///
/// `FlowLayout` works in *breadth* (along the lines) and *depth* (across the lines) rather than width
/// and height, so one implementation serves both axes (see ``Size``). This file holds the type itself,
/// its SwiftUI `Layout` entry points, and the pipeline spine; each pipeline phase lives in its own
/// `FlowLayout+…` file so the directory reads as a table of contents for the algorithm:
///
///   measure → adapt input → break → adapt output → build geometry → distribute space → place
///
/// `FlowLayout+Measurement`, ``LineBreaking``, `FlowLayout+Geometry`, `FlowLayout+SpaceDistribution`,
/// and `FlowLayout+Placement` hold the phases. Optional features (line capping, separators) are not
/// named here at all: they are ``FlowLayoutFeature`` plugins woven in at the two adaptation seams via
/// the ``FlowFeatureSession`` the engine vends per pass, so the core stays unaware of what they do.
struct FlowLayout: Sendable {
    var axis: Axis
    var itemSpacing: CGFloat?
    var lineSpacing: CGFloat?
    var justified: Bool
    var distributeItemsEvenly: Bool
    var alignmentOnBreadth: @Sendable (any Dimensions) -> CGFloat
    var alignmentOnDepth: @Sendable (any Dimensions) -> CGFloat
    /// The optional, additive features woven into the pipeline, in the order they apply at every seam.
    /// Empty means a plain flow with no line capping, no separators, no reporting — the engine names
    /// none of them (see ``FlowLayoutFeature``); each is appended by its own modifier in the view layer.
    var features: [any FlowLayoutFeature]

    init(
        axis: Axis,
        itemSpacing: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        alignmentOnBreadth: @escaping @Sendable (any Dimensions) -> CGFloat,
        alignmentOnDepth: @escaping @Sendable (any Dimensions) -> CGFloat,
        features: [any FlowLayoutFeature] = []
    ) {
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.justified = justified
        self.distributeItemsEvenly = distributeItemsEvenly
        self.alignmentOnBreadth = alignmentOnBreadth
        self.alignmentOnDepth = alignmentOnDepth
        self.features = features
    }

    /// Returns a copy with `feature` appended to the seam order. The engine stays feature-agnostic;
    /// callers (the feature modifiers) decide which features run and in what order.
    func appending(_ feature: any FlowLayoutFeature) -> FlowLayout {
        var copy = self
        copy.features.append(feature)
        return copy
    }

    /// Returns a copy whose seam order is exactly `features`. The view-layer composer builds the list
    /// (in a feature target) and hands it back through here; the engine stays feature-agnostic.
    func withFeatures(_ features: [any FlowLayoutFeature]) -> FlowLayout {
        var copy = self
        copy.features = features
        return copy
    }

    // MARK: - Layout protocol entry points

    func sizeThatFits(
        proposal proposedSize: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let sessions = makeSessions(of: subviews, cache: cache, proposal: proposedSize)
        let result = resolveLayout(in: proposedSize, of: subviews, cache: &cache, sessions: sessions)
        let lines = result.lines
        var size = lines.reduce(Size.zero) { acc, line in
            Size(breadth: max(acc.breadth, line.size.breadth), depth: acc.depth + line.size.depth + line.leadingSpace)
        }
        // Justification needs a finite proposal to stretch to.
        if justified, proposedSize.value(on: axis).isFinite {
            size.breadth = proposedSize.value(on: axis)
        }
        rekeyLineBreaking(toResolvedBreadth: size.breadth, proposal: proposedSize, cache: &cache)
        if proposedSize.value(on: axis).isFinite {
            for session in sessions { session.report(result) }
        }
        return CGSize(size: size, axis: axis)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) {
        guard !subviews.isEmpty else { return }

        var bounds = bounds
        bounds.origin = bounds.origin.finite(or: 0)
        var target = bounds.origin.size(on: axis)
        let effective = effectiveProposal(for: proposal, in: bounds)
        let sessions = makeSessions(of: subviews, cache: cache, proposal: effective)
        let result = resolveLayout(in: effective, of: subviews, cache: &cache, sessions: sessions)

        for line in result.lines {
            advance(&target, \.depth, for: line) { target in
                target.breadth = bounds.minimumValue(on: axis)

                for item in line.items {
                    advance(&target, \.breadth, for: item) { target in
                        alignAndPlace(item, in: line, at: target)
                    }
                }
            }
        }
        placeHiddenSubviews(result.hidden, of: subviews, in: bounds)
        for session in sessions { session.report(result) }
    }

    func makeCache(_ subviews: some Subviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: axis)
    }

    func refreshCache(_ cache: inout FlowLayoutCache, subviews: some Subviews) {
        cache = FlowLayoutCache(subviews, axis: axis)
    }

    /// When `sizeThatFits` was asked with an unbounded breadth, `placeSubviews` substitutes the actual
    /// bounds width (which equals the breadth we just resolved) as the effective proposal. Re-key the
    /// cached line-breaking result to that resolved breadth so the second pass finds it without
    /// recomputing. A no-op when the proposal was already bounded.
    private func rekeyLineBreaking(
        toResolvedBreadth resolvedBreadth: CGFloat,
        proposal: ProposedViewSize,
        cache: inout FlowLayoutCache
    ) {
        guard !proposal.value(on: axis).isFinite, resolvedBreadth.isFinite else { return }
        let key = FlowLayoutCache.LineBreakingKey(
            proposedSize: ProposedViewSize(
                size: Size(breadth: resolvedBreadth, depth: proposal.value(on: axis.perpendicular)),
                axis: axis
            ),
            axis: axis
        )
        cache.rekeyLineBreaking(to: key)
    }

    // MARK: - Pipeline spine

    typealias LayoutResult = FlowLayoutResult

    /// Builds the per-pass feature sessions for `proposal`, dropping any feature that sits this pass out
    /// (``FlowLayoutFeature/makeSession(subviews:cache:context:)`` returned `nil`). The proposal must be
    /// the same one handed to ``resolveLayout(in:of:cache:sessions:)`` so a session's geometry matches.
    func makeSessions(
        of subviews: some Subviews,
        cache: FlowLayoutCache,
        proposal: ProposedViewSize
    ) -> [any FlowFeatureSession] {
        guard !features.isEmpty else { return [] }
        let context = FlowFeatureContext(
            axis: axis,
            itemSpacing: itemSpacing,
            justified: justified,
            proposal: proposal,
            availableBreadth: availableLineBreakingSpace(in: proposal)
        )
        return features.compactMap { $0.makeSession(subviews: subviews, cache: cache, context: context) }
    }

    /// The whole layout, top to bottom. Measurement and line breaking are cached together as the
    /// expensive prefix (``wrappedContentLines(of:in:cache:sessions:)``); the remaining steps run
    /// every pass. Optional features are folded in at two seams via their `sessions`, always in array
    /// order — so e.g. capping runs before separators, truncating content lines (and dropping their
    /// separators) before separators are materialized — without the engine knowing what a feature is.
    func resolveLayout(
        in proposal: ProposedViewSize,
        of subviews: some Subviews,
        cache: inout FlowLayoutCache,
        sessions: [any FlowFeatureSession]
    ) -> LayoutResult {
        // Measure + adapt input + break, in subview-index space (cached as a unit).
        let wrapped = wrappedContentLines(of: subviews, in: proposal, cache: &cache, sessions: sessions)

        // Output seam: each feature returns an adaptation of the current lines, folded onto the result.
        var adapted = LineAdaptation(lines: wrapped)
        for session in sessions {
            adapted.apply(session.adaptOutput(adapted.lines))
        }

        // Build geometry, then distribute leftover space across each line.
        var placed = buildGeometry(of: adapted.lines, of: subviews, cache: cache)
        distributeJustifiedSpace(in: &placed, proposal: proposal)
        applyLineSpacing(in: &placed)
        applyCrossAxisAlignment(in: &placed)

        return LayoutResult(lines: placed, hidden: adapted.hidden, lineStructure: adapted.lineStructure)
    }

    /// The cacheable prefix: measure every subview, adapt the breaker input for the active features
    /// (input seam, array order), break into lines, and resolve positions back to subview indices.
    /// Keyed on the proposed size, so the back-to-back `sizeThatFits`/`placeSubviews` passes share it.
    private func wrappedContentLines(
        of subviews: some Subviews,
        in proposal: ProposedViewSize,
        cache: inout FlowLayoutCache,
        sessions: [any FlowFeatureSession]
    ) -> WrappedLines {
        let key = FlowLayoutCache.LineBreakingKey(proposedSize: proposal, axis: axis)
        if let cached = cache.cachedLineBreaking(for: key) {
            return cached
        }

        var input = measuredItems(of: subviews, in: proposal, cache: cache)
        for session in sessions {
            input = session.adaptInput(input)
        }
        let wrapped = input.resolve(lineBreaker.wrapItemsToLines(items: input.items, in: availableLineBreakingSpace(in: proposal)))
        cache.cacheLineBreaking(wrapped, for: key)
        return wrapped
    }

    private var lineBreaker: any LineBreaking {
        distributeItemsEvenly ? KnuthPlassLineBreaker() : GreedyLineBreaker()
    }
}

// MARK: - Factory

extension FlowLayout {
    static func vertical(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .top,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        self.init(
            axis: .vertical,
            itemSpacing: verticalSpacing,
            lineSpacing: horizontalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            alignmentOnBreadth: { $0[verticalAlignment] },
            alignmentOnDepth: { $0[horizontalAlignment] }
        )
    }

    static func horizontal(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        self.init(
            axis: .horizontal,
            itemSpacing: horizontalSpacing,
            lineSpacing: verticalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            alignmentOnBreadth: { $0[horizontalAlignment] },
            alignmentOnDepth: { $0[verticalAlignment] }
        )
    }
}

// MARK: - Layout protocol

extension FlowLayout: Layout {
    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        makeCache(subviews)
    }

    func updateCache(_ cache: inout FlowLayoutCache, subviews: LayoutSubviews) {
        refreshCache(&cache, subviews: subviews)
    }
}

// MARK: - Pipeline result

/// The finished layout the pipeline produces: placed lines plus the side outputs features report back.
///
/// `package` (the argument of ``FlowFeatureSession/report(_:)``) so features in the feature targets
/// target can read the structural facts they reported on — `hidden` (parked subviews) and
/// `lineStructure` — while `lines` stays internal to the engine.
package struct FlowLayoutResult {
    // Internal to the engine — geometry types are not exposed across the seam.
    var lines: [LayoutLine]
    /// Subview indices parked off-screen (truncated content, unused separators, …).
    package var hidden: [Int]
    /// Line index of every content item (content order), or `nil` when no feature reports it.
    package var lineStructure: [Int]?
}
