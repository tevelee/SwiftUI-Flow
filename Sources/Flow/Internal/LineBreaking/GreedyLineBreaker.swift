import CoreFoundation

/// The default line breaker: greedy. It fills the current line until the next item no longer fits,
/// then starts a new line, without backtracking. ``LineSizer`` checks whether each growing candidate
/// fits; flexibility and priority distribution run only when a line is complete. Feasibility still
/// scans the candidate, so long lines can take quadratic work. The optimal alternative is
/// ``KnuthPlassLineBreaker``.
@usableFromInline
struct GreedyLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [MeasuredItem], in availableSpace: CGFloat) -> WrappedLines {
        let sizer = LineSizer(availableSpace: availableSpace)
        var currentLine: IndexedMeasuredItems = []
        var lines: WrappedLines = []

        for item in items.enumerated() {
            currentLine.append(item)
            if !sizer.fits(currentLine) {
                currentLine.removeLast()
                if !currentLine.isEmpty {
                    lines.append(sizer.resolvedLine(currentLine))
                }
                currentLine = [item]
            }
        }
        if !currentLine.isEmpty {
            lines.append(sizer.resolvedLine(currentLine))
        }
        return lines
    }
}
