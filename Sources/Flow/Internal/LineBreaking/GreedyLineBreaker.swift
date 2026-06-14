import CoreFoundation

/// The default line breaker: greedy. It fills the current line until the next item no longer fits,
/// then starts a new line — a single forward pass, no backtracking. Each line's item breadths are
/// resolved by ``LineSizer``; the optimal alternative is ``KnuthPlassLineBreaker``.
struct GreedyLineBreaker: LineBreaking {

    func wrapItemsToLines(items: [MeasuredItem], in availableSpace: CGFloat) -> WrappedLines {
        let sizer = LineSizer(availableSpace: availableSpace)
        var currentLine: IndexedMeasuredItems = []
        var lines: WrappedLines = []

        for item in items.enumerated() {
            currentLine.append(item)
            if sizer.sizes(of: currentLine) == nil {
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
