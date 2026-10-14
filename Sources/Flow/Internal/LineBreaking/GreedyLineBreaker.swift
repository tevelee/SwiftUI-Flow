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
        var lineStart = items.startIndex
        var lines: WrappedLines = []

        for index in items.indices {
            let item = items[index]
            fitter.append(item)
            if fitter.remainingSpace == nil {
                if lineStart < index {
                    lines.append(sizer.resolvedLine(items[lineStart ..< index]))
                }
                lineStart = index
                fitter = LineFitter(availableSpace: availableSpace)
                fitter.append(item)
            }
        }
        if lineStart < items.endIndex {
            lines.append(sizer.resolvedLine(items[lineStart...]))
        }
        return lines
    }
}
