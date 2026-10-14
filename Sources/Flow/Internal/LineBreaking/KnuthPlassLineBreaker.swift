import CoreFoundation

// The optimal line breaker, used when `distributeItemsEvenly` is set.
//
// Where ``GreedyLineBreaker`` is greedy (fill each line, then wrap), this minimizes a global cost —
// squared leftover space per line, plus a stretch penalty and a small bias toward fewer lines — via
// dynamic programming over break points. Non-growing candidates need only ``LineFitter``; flexible
// candidates use ``LineSizer`` to score stretch. Only costs and break points are retained, and
// chosen lines are sized during reconstruction.

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
    /// Finite minima and zero growth make stretch zero; scoring needs no sized-item array.
    let canScoreWithoutSizing: Bool
    /// Whether `chooseBestBreak` may stop as soon as a multi-item range overflows.
    /// Widening a range by an earlier item grows its minimum width by that item's
    /// (non-negative) size plus the following spacing, so with non-negative spacing
    /// the minimum width is monotonic: once a range overflows, every wider range
    /// overflows too. Negative spacing breaks that monotonicity — a wider range can
    /// shrink back under the limit and fit — so we must keep scanning in that case.
    let mayStopAtFirstOverflow: Bool

    @usableFromInline
    init(items: [MeasuredItem], availableSpace: CGFloat) {
        self.items = items
        self.availableSpace = availableSpace
        canScoreWithoutSizing = items.allSatisfy { $0.growingPotential == 0 && $0.size.lowerBound.isFinite }
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
        for end in 1 ... items.count {
            chooseBestBreak(endingAt: end)
        }
        return rebuildLines()
    }

    private mutating func chooseBestBreak(endingAt end: Int) {
        for start in (0 ..< end).reversed() {
            let range = start ..< end
            guard let candidateCost = candidateCost(for: range) else {
                // A multi-item range that doesn't fit means all wider ranges (lower
                // start values) also won't fit: overflow only grows (when spacing is
                // non-negative, see `mayStopAtFirstOverflow`), and structural violations
                // (line-break / shouldStartInNewLine at non-first position) move further
                // from position 0 as start decreases. Negative spacing can shrink a wider
                // range back under the limit, so keep scanning when it is present.
                if range.count > 1, mayStopAtFirstOverflow { break }
                continue
            }
            if candidateCost < costs[end] {
                costs[end] = candidateCost
                breaks[end] = start
            }
        }
    }

    private func candidateCost(for range: Range<Int>) -> CGFloat? {
        guard let penalties = penalties(for: range) else {
            return nil
        }
        return costs[range.lowerBound] + penalties.space + penalties.stretch + lineCountBias(for: range.lowerBound)
    }

    private func penalties(for range: Range<Int>) -> (space: CGFloat, stretch: CGFloat)? {
        if canScoreWithoutSizing {
            var fitter = LineFitter(availableSpace: availableSpace)
            for item in items[range] { fitter.append(item) }
            if let remaining = fitter.remainingSpace { return (space: remaining * remaining, stretch: 0) }
        } else if let calculation = LineSizer(availableSpace: availableSpace).sizes(of: indexedItems(in: range)) {
            let remaining = calculation.remainingSpace
            return (
                space: remaining * remaining,
                stretch: stretchPenalty(for: calculation, in: range)
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

    private func stretchPenalty(for calculation: SizedLine, in range: Range<Int>) -> CGFloat {
        zip(range, calculation.items).sum { index, output in
            let deviation = output.size - items[index].size.lowerBound
            return deviation * deviation
        }
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
            let line = LineSizer(availableSpace: availableSpace).resolvedLine(indexedItems(in: range))
            result.append(line)
            end = start
        }
        result.reverse()
        return result
    }

    private func indexedItems(in range: Range<Int>) -> IndexedMeasuredItems {
        range.map { ($0, items[$0]) }
    }
}
