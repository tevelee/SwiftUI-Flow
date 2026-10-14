import CoreFoundation

/// The line-cap feature: truncation to `maxLines` and optional overflow-indicator placement.
///
/// ``FlowLayout`` excludes the overflow indicator when preparing capped content for line breaking.
/// This module then drops lines beyond the limit and fits the indicator on the last visible line,
/// using the same separator-aware spacing as input preparation and materialization.
@usableFromInline
struct LineCap: Sendable {
    @usableFromInline var maxLines: Int

    @inlinable
    init(maxLines: Int) {
        self.maxLines = maxLines
    }

    /// Truncates the wrapped lines to `maxLines`, returning the hidden subviews, and places the
    /// overflow indicator (if any) on the last visible line.
    func truncate(
        _ lines: WrappedLines,
        available: CGFloat,
        cache: FlowLayoutCache,
        spacingBefore: (Int, Int) -> CGFloat
    ) -> LineAdaptation {
        var (visible, hidden) = splitAtLimit(lines)
        if let overflowIndex = cache.overflowSubviewIndex {
            placeOrHideOverflowIndicator(
                at: overflowIndex,
                visible: &visible,
                hidden: &hidden,
                available: available,
                spacingBefore: spacingBefore,
                sizeOf: { cache.subviewsCache[$0].ideal.breadth }
            )
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
        hidden: inout [Int],
        available: CGFloat,
        spacingBefore: (Int, Int) -> CGFloat,
        sizeOf: (Int) -> CGFloat
    ) {
        guard !hidden.isEmpty, !visible.isEmpty else {
            hidden.append(overflowIdx)
            return
        }
        let overflowWidth = sizeOf(overflowIdx)
        let trimmed = trimLastLine(&visible, toFit: overflowWidth, available: available) { previous in
            spacingBefore(overflowIdx, previous)
        }
        hidden.append(contentsOf: trimmed)
        let leadingSpace = visible[visible.count - 1].last.map { spacingBefore(overflowIdx, $0.index) } ?? 0
        visible[visible.count - 1].append(WrappedItem(index: overflowIdx, size: overflowWidth, leadingSpace: leadingSpace))
    }

    /// Removes trailing items from the last line until `needed` fits within `available`.
    /// Returns the indices of removed items.
    private func trimLastLine(
        _ lines: inout WrappedLines,
        toFit needed: CGFloat,
        available: CGFloat,
        spacingAfter: (Int) -> CGFloat
    ) -> [Int] {
        guard !lines.isEmpty else { return [] }
        var removed: [Int] = []
        var lastLineWidth = lines[lines.count - 1].reduce(0) { $0 + $1.size + $1.leadingSpace }
        while let last = lines[lines.count - 1].last, lastLineWidth + needed + spacingAfter(last.index) > available + 1e-9 {
            let item = lines[lines.count - 1].removeLast()
            removed.append(item.index)
            lastLineWidth -= (item.size + item.leadingSpace)
        }
        return removed
    }
}
