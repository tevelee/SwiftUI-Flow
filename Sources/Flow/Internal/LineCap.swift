import CoreFoundation

/// Encapsulates the line-cap feature: truncation to `maxLines` and optional overflow-indicator placement.
///
/// All `.maxLines()` logic lives here so the core `FlowLayout` algorithm is unaware of line limits.
/// `FlowLayout` calls `apply(to:…)` once per layout pass; the result is a plain
/// `(visible lines, hidden indices)` value it can act on without further knowledge.
@usableFromInline
struct LineCap: Sendable {
    @usableFromInline var maxLines: Int

    @inlinable
    init(maxLines: Int) {
        self.maxLines = maxLines
    }

    struct Result {
        var visible: LineBreakingOutput
        var hidden: [Int]
    }

    /// Truncates `lines` to `maxLines` and optionally inserts the overflow indicator on the last visible line.
    ///
    /// - Parameters:
    ///   - lines: Raw line-breaking output (all lines, before any cap).
    ///   - overflowIndex: Index of the overflow-indicator subview, or `nil` if none is present.
    ///   - available: Available breadth (used to decide whether the indicator fits).
    ///   - spacingBefore: Returns the leading space for a given subview index.
    ///   - sizeOf: Returns the ideal breadth for a given subview index.
    func apply(
        to lines: LineBreakingOutput,
        overflowIndex: Int?,
        available: CGFloat,
        spacingBefore: (Int) -> CGFloat,
        sizeOf: (Int) -> CGFloat
    ) -> Result {
        var (visible, hidden) = truncate(lines)

        if let overflowIndex {
            placeOrHideOverflowIndicator(
                at: overflowIndex,
                visible: &visible,
                hidden: &hidden,
                available: available,
                spacingBefore: spacingBefore,
                sizeOf: sizeOf
            )
        }

        return Result(visible: visible, hidden: hidden)
    }

    // MARK: - Truncation

    private func truncate(_ lines: LineBreakingOutput) -> (visible: LineBreakingOutput, hidden: [Int]) {
        let limit = max(0, maxLines)
        guard lines.count > limit else { return (lines, []) }
        let visible = Array(lines.prefix(limit))
        let hidden = lines.dropFirst(limit).flatMap { $0.map(\.index) }
        return (visible, hidden)
    }

    // MARK: - Overflow indicator

    /// Places the overflow indicator at the end of the last visible line, trimming items to make room.
    /// If nothing was hidden (all items fit) or no lines are visible, hides the indicator instead.
    private func placeOrHideOverflowIndicator(
        at overflowIdx: Int,
        visible: inout LineBreakingOutput,
        hidden: inout [Int],
        available: CGFloat,
        spacingBefore: (Int) -> CGFloat,
        sizeOf: (Int) -> CGFloat
    ) {
        guard !hidden.isEmpty, !visible.isEmpty else {
            hidden.append(overflowIdx)
            return
        }
        let overflowWidth = sizeOf(overflowIdx)
        let overflowSpacing = spacingBefore(overflowIdx)
        let trimmed = trimLastLine(&visible, toFit: overflowWidth + overflowSpacing, available: available)
        hidden.append(contentsOf: trimmed)
        let leadingSpace = visible[visible.count - 1].isEmpty ? 0 : overflowSpacing
        visible[visible.count - 1].append(LineItemOutput(index: overflowIdx, size: overflowWidth, leadingSpace: leadingSpace))
    }

    /// Removes trailing items from the last line until `needed` fits within `available`.
    /// Returns the indices of removed items.
    private func trimLastLine(
        _ lines: inout LineBreakingOutput,
        toFit needed: CGFloat,
        available: CGFloat
    ) -> [Int] {
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
}
