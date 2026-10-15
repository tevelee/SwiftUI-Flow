import CoreFoundation

// The optimal line breaker, used when `distributeItemsEvenly` is set.
//
// Where ``GreedyLineBreaker`` is greedy (fill each line, then wrap), this minimizes a global cost —
// squared leftover space per line, plus a stretch penalty and a small bias toward fewer lines — via
// dynamic programming over break points. Each start extends its candidates with one incremental
// ``LineFitter``. ``LineSizer`` scores growth without a wrapped-item buffer for uniform candidates.
// Only costs and break points are retained, and chosen lines are sized during reconstruction.

@usableFromInline
struct KnuthPlassLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [MeasuredItem], in availableSpace: CGFloat) -> WrappedLines {
        // With unbounded space there is nothing to optimize: wrapping never reduces
        // the squared-leftover cost, so every candidate scores an infinite penalty and
        // the solver would record no break points (dropping all items). Fall back to the
        // greedy breaker, which keeps everything on one line (honoring manual breaks).
        guard availableSpace.isFinite else {
            return GreedyLineBreaker().wrapItemsToLines(items: items, in: availableSpace)
        }
        var solver = KnuthPlassSolver(items: items, availableSpace: availableSpace)
        return solver.solve()
    }
}

@usableFromInline
struct KnuthPlassSolver {
    let items: [MeasuredItem]
    let availableSpace: CGFloat
    var costs: [CGFloat]
    var breaks: [Int?]
    /// Appending non-negative sizes and spacing cannot shrink a candidate's minimum breadth.
    /// Structural violations also persist as it grows. Negative spacing can make a later
    /// candidate fit again, so scanning must continue after overflow when it is present.
    let mayStopAtFirstOverflow: Bool

    @usableFromInline
    init(items: [MeasuredItem], availableSpace: CGFloat) {
        self.items = items
        self.availableSpace = availableSpace
        costs = Array(repeating: .infinity, count: items.count + 1)
        breaks = Array(repeating: nil, count: items.count + 1)
        // Only the spacing between items (every spacing except the first item's, which
        // never contributes to a line's width) can turn the minimum width non-monotonic.
        mayStopAtFirstOverflow = items.dropFirst().allSatisfy { $0.spacing >= 0 }
    }

    @usableFromInline
    mutating func solve() -> WrappedLines {
        guard !items.isEmpty else {
            return []
        }

        costs[0] = 0
        for start in items.indices {
            chooseBestBreak(startingAt: start)
        }
        return rebuildLines()
    }

    private mutating func chooseBestBreak(startingAt start: Int) {
        // The cost of reaching `start` is final: every earlier start has already offered
        // its candidates. Extend each candidate in encounter order to preserve fit arithmetic.
        var fitter = LineFitter(availableSpace: availableSpace)
        var canScoreWithoutSizing = true
        var workspace = LineSizingWorkspace()
        for end in (start + 1) ... items.count {
            let range = start ..< end
            let item = items[end - 1]
            // A structural break cannot be recovered by later negative spacing.
            if range.count > 1, item.isLineBreakView || item.shouldStartInNewLine { break }
            fitter.append(item)
            canScoreWithoutSizing = canScoreWithoutSizing && item.growingPotential == 0 && item.size.lowerBound.isFinite
            guard
                let penalties = penalties(
                    for: range,
                    remainingSpace: fitter.remainingSpace,
                    canScoreWithoutSizing: canScoreWithoutSizing,
                    workspace: &workspace
                )
            else {
                if range.count > 1, mayStopAtFirstOverflow { break }
                continue
            }
            let candidateCost = costs[start] + penalties.space + penalties.stretch + lineCountBias(for: start)
            // Starts arrive in ascending order. Replace equal finite costs to retain the
            // previous reverse scan's preference for the latest break point.
            if candidateCost < costs[end] || (candidateCost == costs[end] && breaks[end] != nil) {
                costs[end] = candidateCost
                breaks[end] = start
            }
        }
    }

    private func penalties(
        for range: Range<Int>,
        remainingSpace: CGFloat?,
        canScoreWithoutSizing: Bool,
        workspace: inout LineSizingWorkspace
    ) -> (space: CGFloat, stretch: CGFloat)? {
        if let remainingSpace {
            if canScoreWithoutSizing { return (space: remainingSpace * remainingSpace, stretch: 0) }
            let calculation = LineSizer(availableSpace: availableSpace).metrics(of: items[range], remainingSpace: remainingSpace, workspace: &workspace)
            let remaining = calculation.remainingSpace
            return (
                space: remaining * remaining,
                stretch: calculation.squaredGrowth
            )
        }

        guard range.count == 1, let overflow = overflowPenalty(for: items[range.lowerBound]) else {
            return nil
        }
        return (space: overflow * overflow, stretch: 0)
    }

    private func lineCountBias(for start: Int) -> CGFloat {
        // Bias toward fewer lines: every chosen break contributes this term, and
        // earlier break points (smaller `start`, i.e. more items deferred to later
        // lines) contribute more, nudging the solver to fill earlier lines first.
        // The weight is a heuristic kept small relative to the squared space/stretch
        // penalties so it mainly breaks ties between otherwise comparable layouts.
        CGFloat(items.count - start) * 5
    }

    private func overflowPenalty(for item: MeasuredItem) -> CGFloat? {
        let overflow = item.size.lowerBound - availableSpace
        return overflow > 0 ? overflow : nil
    }

    private func rebuildLines() -> WrappedLines {
        var result: WrappedLines = []
        var end = items.count
        while let start = breaks[end] {
            let range = start ..< end
            let line = LineSizer(availableSpace: availableSpace).resolvedLine(items[range])
            result.append(line)
            end = start
        }
        result.reverse()
        return result
    }

}
