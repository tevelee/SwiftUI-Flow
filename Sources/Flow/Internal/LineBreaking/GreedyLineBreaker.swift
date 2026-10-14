import CoreFoundation

/// The default line breaker: greedy. It fills the current line until the next item no longer fits,
/// then starts a new line, without backtracking. ``LineFitter`` tracks each growing candidate,
/// giving linear fitting work for lines without `.maximum` demands. ``LineSizer`` distributes
/// flexibility and priority only when a line is complete. The optimal alternative is ``KnuthPlassLineBreaker``.
@usableFromInline
struct GreedyLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [MeasuredItem], in availableSpace: CGFloat) -> WrappedLines {
        let sizer = LineSizer(availableSpace: availableSpace)
        var fitter = LineFitter(availableSpace: availableSpace)
        var currentLine: IndexedMeasuredItems = []
        var lines: WrappedLines = []

        for item in items.enumerated() {
            currentLine.append(item)
            fitter.append(item.element)
            if fitter.remainingSpace == nil {
                currentLine.removeLast()
                if !currentLine.isEmpty {
                    lines.append(sizer.resolvedLine(currentLine))
                }
                currentLine = [item]
                fitter = LineFitter(availableSpace: availableSpace)
                fitter.append(item.element)
            }
        }
        if !currentLine.isEmpty {
            lines.append(sizer.resolvedLine(currentLine))
        }
        return lines
    }
}
