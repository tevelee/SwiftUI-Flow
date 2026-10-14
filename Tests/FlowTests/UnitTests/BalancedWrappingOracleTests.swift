import CoreFoundation
import Testing

@testable import Flow

@Suite(.tags(.requirements, .invariant))
struct BalancedWrappingOracleTests {
    @Test func smallRigidLayouts_matchExhaustivePartitions() {
        // Integer, rigid inputs deliberately keep the oracle independent of LineFitter/LineSizer.
        // Enumerate negative gaps, oversized items, manual breaks and forced starts as well as ties.
        let choices: [MeasuredItem] = [
            .init(size: 2 ... 2, spacing: 1),
            .init(size: 7 ... 7, spacing: -2),
            .init(size: 0 ... 0, spacing: 3, isLineBreakView: true),
            .init(size: 3 ... 3, spacing: 0, shouldStartInNewLine: true),
        ]
        for count in 1 ... 5 {
            let combinations = (0 ..< count).reduce(1) { value, _ in value * choices.count }
            for code in 0 ..< combinations {
                var digits = code
                let items = (0 ..< count).map { _ in
                    defer { digits /= choices.count }
                    return choices[digits % choices.count]
                }
                for breadth: CGFloat in [3, 6, 9] {
                    let expected = exhaustiveRigidWrapping(items, breadth: breadth)
                    let actual = KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: breadth)
                    #expect(actual == expected, "count:\(count) case:\(code) breadth:\(breadth)")
                }
            }
        }
    }
}

/// Enumerates every partition; no dynamic programming, production fitting, or production sizing.
/// Scope: small rigid integer inputs. Flexible allocation and floating-point rules have exact tests.
private func exhaustiveRigidWrapping(_ items: [MeasuredItem], breadth: CGFloat) -> WrappedLines {
    var bestCost = CGFloat.infinity
    var bestStarts: [Int] = []
    var best: WrappedLines = []
    for mask in 0 ..< (1 << (items.count - 1)) {
        let starts = [0] + (1 ..< items.count).filter { mask & (1 << ($0 - 1)) != 0 }
        let ends = Array(starts.dropFirst()) + [items.count]
        var cost: CGFloat = 0
        var lines: WrappedLines = []
        var valid = true
        for (start, end) in zip(starts, ends) {
            let range = start ..< end
            if range.dropFirst().contains(where: { items[$0].isLineBreakView || items[$0].shouldStartInNewLine }) {
                valid = false
                break
            }
            let line = range.map { index in
                let clearsSpacing = index == start || (index == start + 1 && items[start].isLineBreakView)
                return WrappedItem(index: index, size: items[index].size.lowerBound, leadingSpace: clearsSpacing ? 0 : items[index].spacing)
            }
            let used = line.reduce(CGFloat.zero) { $0 + $1.size + $1.leadingSpace }
            if used > breadth && range.count > 1 {
                valid = false
                break
            }
            let difference = breadth - used
            cost += difference * difference + CGFloat(items.count - start) * 5
            lines.append(line)
        }
        // Equal-cost solutions choose the latest final break, then the latest preceding break.
        let laterBreaks = bestStarts.reversed().lexicographicallyPrecedes(starts.reversed())
        if valid && (cost < bestCost || (cost == bestCost && laterBreaks)) {
            bestCost = cost
            bestStarts = starts
            best = lines
        }
    }
    return best
}
