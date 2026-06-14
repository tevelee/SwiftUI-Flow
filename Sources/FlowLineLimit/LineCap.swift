import CoreFoundation
import Flow
import SwiftUI

/// The line-cap feature: truncation to `maxLines` and optional overflow-indicator placement.
///
/// All `.maxLines()` logic lives here so the core ``FlowLayout`` engine stays unaware of line limits —
/// it sees only an opaque ``FlowLayoutFeature``. The feature vends a ``LineCapSession`` that the engine
/// folds in at its two seams:
///
/// * ``LineCapSession/adaptInput(_:)`` keeps the overflow indicator out of line breaking — it is placed
///   separately, so it must not consume space or affect where items wrap.
/// * ``LineCapSession/adaptOutput(_:)`` drops lines beyond the limit and places the overflow indicator
///   on the last visible line.
/// * ``LineCapSession/report(_:)`` reports how many content items the cap hid.
struct LineCap: FlowLayoutFeature {
    var maxLines: Int

    func makeSession(
        subviews: some Subviews,
        cache: FlowLayoutCache,
        context: FlowFeatureContext
    ) -> (any FlowFeatureSession)? {
        LineCapSession(maxLines: maxLines, subviews: subviews, cache: cache, context: context)
    }
}

/// The per-pass worker for ``LineCap``. Captures everything it needs from the subviews and cache at
/// creation, so the seam hooks take only the value flowing through them.
struct LineCapSession: FlowFeatureSession {
    private let maxLines: Int
    private let cache: FlowLayoutCache
    private let axis: Axis
    private let itemSpacing: CGFloat?
    private let available: CGFloat
    /// Index of the overflow-indicator subview (the last subview if it carries ``IsOverflowLayoutValueKey``).
    private let overflowIndex: Int?
    private let overflowReporter: (@Sendable (Int) -> Void)?
    /// `true` for subviews that count toward the hidden total — caller content, not injected auxiliaries.
    private let isContent: [Bool]
    private let isLineBreak: [Bool]

    init(maxLines: Int, subviews: some Subviews, cache: FlowLayoutCache, context: FlowFeatureContext) {
        self.maxLines = maxLines
        self.cache = cache
        axis = context.axis
        itemSpacing = context.itemSpacing
        available = context.availableBreadth
        if let last = subviews.indices.last, subviews[last][IsOverflowLayoutValueKey.self] {
            overflowIndex = last
            overflowReporter = subviews[last][OverflowReporterKey.self]
        } else {
            overflowIndex = nil
            overflowReporter = nil
        }
        isContent = subviews.map { !$0[IsAuxiliaryLayoutValueKey.self] }
        isLineBreak = cache.subviewsCache.map { $0.layoutValues.isLineBreak }
    }

    // MARK: - Seams

    func adaptInput(_ input: BreakerInput) -> BreakerInput {
        excludeOverflowIndicator(from: input)
    }

    func adaptOutput(_ lines: WrappedLines) -> LineAdaptation {
        truncate(lines)
    }

    func report(_ result: FlowLayoutResult) {
        guard let overflowReporter else { return }
        let count = result.hidden.filter { index in
            index != overflowIndex && isContent[index] && !isLineBreak[index]
        }.count
        overflowReporter(count)
    }

    // MARK: - Input seam

    /// Removes the overflow indicator from the breaker input. It is placed separately on the last
    /// visible line in ``truncate(_:)``, so it must not take part in line breaking.
    private func excludeOverflowIndicator(from input: BreakerInput) -> BreakerInput {
        guard let overflowIndex,
            let position = input.subviewIndices.firstIndex(of: overflowIndex)
        else { return input }
        var input = input
        input.items.remove(at: position)
        input.subviewIndices.remove(at: position)
        return input
    }

    // MARK: - Output seam

    /// Truncates the wrapped lines to `maxLines`, returning the hidden subviews, and places the
    /// overflow indicator (if any) on the last visible line.
    private func truncate(_ lines: WrappedLines) -> LineAdaptation {
        var (visible, hidden) = splitAtLimit(lines)
        if let overflowIndex {
            placeOrHideOverflowIndicator(at: overflowIndex, visible: &visible, hidden: &hidden)
        }
        return LineAdaptation(lines: visible, hidden: hidden)
    }

    /// Splits the lines into the first `maxLines` (visible) and the subview indices of everything
    /// beyond the limit (hidden).
    private func splitAtLimit(_ lines: WrappedLines) -> (visible: WrappedLines, hidden: [Int]) {
        let limit = max(0, maxLines)
        guard lines.count > limit else { return (lines, []) }
        let visible = Array(lines.prefix(limit))
        let hidden = lines.dropFirst(limit).flatMap { $0.map(\.index) }
        return (visible, hidden)
    }

    /// Places the overflow indicator at the end of the last visible line, trimming items to make room.
    /// If nothing was hidden (all items fit) or no lines are visible, hides the indicator instead.
    private func placeOrHideOverflowIndicator(
        at overflowIdx: Int,
        visible: inout WrappedLines,
        hidden: inout [Int]
    ) {
        guard !hidden.isEmpty, !visible.isEmpty else {
            hidden.append(overflowIdx)
            return
        }
        let overflowWidth = cache.subviewsCache[overflowIdx].ideal.breadth
        let overflowSpacing = spacing(before: overflowIdx)
        let trimmed = trimLastLine(&visible, toFit: overflowWidth + overflowSpacing)
        hidden.append(contentsOf: trimmed)
        let leadingSpace = visible[visible.count - 1].isEmpty ? 0 : overflowSpacing
        visible[visible.count - 1].append(WrappedItem(index: overflowIdx, size: overflowWidth, leadingSpace: leadingSpace))
    }

    /// Removes trailing items from the last line until `needed` fits within `available`.
    /// Returns the indices of removed items.
    private func trimLastLine(_ lines: inout WrappedLines, toFit needed: CGFloat) -> [Int] {
        guard !lines.isEmpty else { return [] }
        var removed: [Int] = []
        var lastLineWidth = lines[lines.count - 1].reduce(0) { $0 + $1.size + $1.leadingSpace }
        while lastLineWidth + needed > available + 1e-9 {
            guard !lines[lines.count - 1].isEmpty else { break }
            let item = lines[lines.count - 1].removeLast()
            removed.append(item.index)
            lastLineWidth -= (item.size + item.leadingSpace)
        }
        return removed
    }

    /// Spacing before the subview at `index`: the explicit `itemSpacing` if set, otherwise the subviews'
    /// combined `ViewSpacing` preferences. Zero before the first subview.
    private func spacing(before index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        return cache.spacing(from: index - 1, to: index, itemSpacing: itemSpacing, axis: axis)
    }
}

// MARK: - Public layout wiring

extension HFlowLayout {
    /// Returns a copy of this layout capped to `maxLines` rows.
    /// Items beyond the limit are hidden; pass `nil` to remove any cap.
    public func withMaxLines(_ maxLines: Int?) -> HFlowLayout {
        maxLines.map { withFeatures([LineCap(maxLines: $0)]) } ?? self
    }
}

extension VFlowLayout {
    /// Returns a copy of this layout capped to `maxLines` columns.
    /// Items beyond the limit are hidden; pass `nil` to remove any cap.
    public func withMaxLines(_ maxLines: Int?) -> VFlowLayout {
        maxLines.map { withFeatures([LineCap(maxLines: $0)]) } ?? self
    }
}

// MARK: - Overflow markers

/// Tags the last subview as the overflow indicator so ``LineCap`` keeps it out of line breaking and
/// places it on the last visible line. Set by ``LineLimitComposer`` via ``overflowIndicator(reporter:)``.
struct IsOverflowLayoutValueKey: LayoutValueKey {
    static let defaultValue = false
}

/// Reporter ``LineCap`` calls with the number of content items the cap hid.
struct OverflowReporterKey: LayoutValueKey {
    static let defaultValue: (@Sendable (Int) -> Void)? = nil
}
