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
/// and `FlowLayout+Placement` hold the phases; ``LineCap`` and ``SeparatorLayout`` are the optional
/// feature collaborators woven in at the two adaptation seams.
@usableFromInline
struct FlowLayout: Sendable {
    @usableFromInline
    var axis: Axis
    @usableFromInline
    var itemSpacing: CGFloat?
    @usableFromInline
    var lineSpacing: CGFloat?
    @usableFromInline
    var justified: Bool
    @usableFromInline
    var distributeItemsEvenly: Bool
    @usableFromInline
    var alignmentOnBreadth: @Sendable (any Dimensions) -> CGFloat
    @usableFromInline
    var alignmentOnDepth: @Sendable (any Dimensions) -> CGFloat
    /// When set, caps the layout to `lineCap.maxLines` lines and optionally reports the overflow count.
    /// Nil means unlimited lines (no capping, no reporting).
    @usableFromInline
    var lineCap: LineCap?

    @inlinable
    init(
        axis: Axis,
        itemSpacing: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        alignmentOnBreadth: @escaping @Sendable (any Dimensions) -> CGFloat,
        alignmentOnDepth: @escaping @Sendable (any Dimensions) -> CGFloat,
        lineCap: LineCap? = nil
    ) {
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.justified = justified
        self.distributeItemsEvenly = distributeItemsEvenly
        self.alignmentOnBreadth = alignmentOnBreadth
        self.alignmentOnDepth = alignmentOnDepth
        self.lineCap = lineCap
    }

    @inlinable
    func withMaxLines(_ maxLines: Int?) -> FlowLayout {
        var copy = self
        copy.lineCap = maxLines.map { LineCap(maxLines: $0) }
        return copy
    }

    // MARK: - Layout protocol entry points

    @usableFromInline
    func sizeThatFits(
        proposal proposedSize: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let result = resolveLayout(in: proposedSize, of: subviews, cache: &cache)
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
            notifyOverflowReporter(hidden: result.hidden, cache: cache)
            notifyLineStructureReporter(result.lineStructure, cache: cache)
        }
        return CGSize(size: size, axis: axis)
    }

    @usableFromInline
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
        let result = resolveLayout(in: effectiveProposal(for: proposal, in: bounds), of: subviews, cache: &cache)

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
        notifyOverflowReporter(hidden: result.hidden, cache: cache)
        notifyLineStructureReporter(result.lineStructure, cache: cache)
    }

    @usableFromInline
    func makeCache(_ subviews: some Subviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: axis)
    }

    @usableFromInline
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

    struct LayoutResult {
        var lines: [LayoutLine]
        var hidden: [Int]
        /// Line index of every content item (content order), or `nil` when no step reports it.
        var lineStructure: [Int]?
    }

    /// The whole layout, top to bottom. Measurement and line breaking are cached together as the
    /// expensive prefix (``wrappedContentLines(of:in:cache:separators:)``); the remaining steps run
    /// every pass. ``LineCap`` (line limits) and ``SeparatorLayout`` (separators) are optional
    /// collaborators woven in at two seams, always in the same order — capping before separators, so
    /// truncation counts content lines (and drops their separators) before separators are materialized.
    func resolveLayout(
        in proposal: ProposedViewSize,
        of subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> LayoutResult {
        let separators = SeparatorLayout(cache: cache, axis: axis, itemSpacing: itemSpacing)

        // Measure + adapt input + break, in subview-index space (cached as a unit).
        let wrapped = wrappedContentLines(of: subviews, in: proposal, cache: &cache, separators: separators)

        // Output seam: adapt the wrapped lines for whichever features are active (same fixed order).
        // Each step returns an adaptation of the current lines, which folds onto the running result.
        var adapted = LineAdaptation(lines: wrapped)
        if let lineCap {
            adapted.apply(
                lineCap.truncate(
                    adapted.lines,
                    available: availableLineBreakingSpace(in: proposal),
                    cache: cache,
                    spacingBefore: { spacing(before: $0, cache: cache) }
                )
            )
        }
        if let separators {
            adapted.apply(separators.materialize(in: adapted.lines, justified: justified, proposal: proposal))
        }

        // Build geometry, then distribute leftover space across each line.
        var placed = buildGeometry(of: adapted.lines, of: subviews, cache: cache)
        distributeJustifiedSpace(in: &placed, proposal: proposal)
        applyLineSpacing(in: &placed)
        applyCrossAxisAlignment(in: &placed)

        return LayoutResult(lines: placed, hidden: adapted.hidden, lineStructure: adapted.lineStructure)
    }

    /// The cacheable prefix: measure every subview, adapt the breaker input for the active features
    /// (input seam, fixed order), break into lines, and resolve positions back to subview indices.
    /// Keyed on the proposed size, so the back-to-back `sizeThatFits`/`placeSubviews` passes share it.
    private func wrappedContentLines(
        of subviews: some Subviews,
        in proposal: ProposedViewSize,
        cache: inout FlowLayoutCache,
        separators: SeparatorLayout?
    ) -> WrappedLines {
        let key = FlowLayoutCache.LineBreakingKey(proposedSize: proposal, axis: axis)
        if let cached = cache.cachedLineBreaking(for: key) {
            return cached
        }

        var input = measuredItems(of: subviews, in: proposal, cache: cache)
        if let lineCap {
            input = lineCap.excludeOverflowIndicator(from: input, cache: cache)
        }
        if let separators {
            input = separators.foldIntoContent(input)
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
    @inlinable
    static func vertical(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .top,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        maxLines: Int? = nil
    ) -> FlowLayout {
        self.init(
            axis: .vertical,
            itemSpacing: verticalSpacing,
            lineSpacing: horizontalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            alignmentOnBreadth: { $0[verticalAlignment] },
            alignmentOnDepth: { $0[horizontalAlignment] },
            lineCap: maxLines.map { LineCap(maxLines: $0) }
        )
    }

    @inlinable
    static func horizontal(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        maxLines: Int? = nil
    ) -> FlowLayout {
        self.init(
            axis: .horizontal,
            itemSpacing: horizontalSpacing,
            lineSpacing: verticalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            alignmentOnBreadth: { $0[horizontalAlignment] },
            alignmentOnDepth: { $0[verticalAlignment] },
            lineCap: maxLines.map { LineCap(maxLines: $0) }
        )
    }
}

// MARK: - Layout protocol

extension FlowLayout: Layout {
    @inlinable
    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        makeCache(subviews)
    }

    @inlinable
    func updateCache(_ cache: inout FlowLayoutCache, subviews: LayoutSubviews) {
        refreshCache(&cache, subviews: subviews)
    }
}
