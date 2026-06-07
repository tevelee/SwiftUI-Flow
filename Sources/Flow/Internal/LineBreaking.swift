import CoreFoundation
import Foundation

@usableFromInline
struct LineItemInput: Sendable {
    @usableFromInline
    var size: ClosedRange<CGFloat>
    @usableFromInline
    var spacing: CGFloat
    @usableFromInline
    var priority: Double = 0
    @usableFromInline
    var flexibility: FlexibilityBehavior = .natural
    @usableFromInline
    var isLineBreakView: Bool = false
    @usableFromInline
    var shouldStartInNewLine: Bool = false
    @inlinable
    var growingPotential: Double {
        guard flexibility == .minimum else {
            return size.upperBound - size.lowerBound
        }
        return 0
    }
}

@usableFromInline
protocol LineBreaking {
    @inlinable
    func wrapItemsToLines(items: LineBreakingInput, in availableSpace: CGFloat) -> LineBreakingOutput
}

@usableFromInline
typealias LineBreakingInput = [LineItemInput]

@usableFromInline
typealias IndexedLineBreakingInput = [(offset: Int, element: LineItemInput)]

@usableFromInline
typealias LineBreakingOutput = [LineOutput]

@usableFromInline
typealias LineOutput = [LineItemOutput]

@usableFromInline
struct LineItemOutput: Equatable {
    @usableFromInline
    let index: Int
    @usableFromInline
    var size: CGFloat
    @usableFromInline
    var leadingSpace: CGFloat

    @inlinable
    init(index: Int, size: CGFloat, leadingSpace: CGFloat) {
        self.index = index
        self.size = size
        self.leadingSpace = leadingSpace
    }
}

@usableFromInline
struct FlowLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: LineBreakingInput, in availableSpace: CGFloat) -> LineBreakingOutput {
        var currentLine: IndexedLineBreakingInput = []
        var lines: LineBreakingOutput = []

        for item in items.enumerated() {
            currentLine.append(item)
            if sizes(of: currentLine, availableSpace: availableSpace) == nil {
                currentLine.removeLast()
                if !currentLine.isEmpty {
                    lines.append(resolvedLine(currentLine, availableSpace: availableSpace))
                }
                currentLine = [item]
            }
        }
        if !currentLine.isEmpty {
            lines.append(resolvedLine(currentLine, availableSpace: availableSpace))
        }
        return lines
    }
}

@usableFromInline
struct KnuthPlassLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: LineBreakingInput, in availableSpace: CGFloat) -> LineBreakingOutput {
        // With unbounded space there is nothing to optimize: wrapping never reduces
        // the squared-leftover cost, so every candidate scores an infinite penalty and
        // the solver would record no break points (dropping all items). Fall back to the
        // greedy breaker, which keeps everything on one line (honoring manual breaks).
        guard availableSpace.isFinite else {
            return FlowLineBreaker().wrapItemsToLines(items: items, in: availableSpace)
        }
        var solver = KnuthPlassSolver(items: items, availableSpace: availableSpace)
        return solver.solve()
    }
}

@usableFromInline
struct KnuthPlassSolver {
    let items: LineBreakingInput
    let availableSpace: CGFloat
    var costs: [CGFloat]
    var breaks: [Int?]
    var sizeCache: SegmentSizingCache

    @usableFromInline
    init(items: LineBreakingInput, availableSpace: CGFloat) {
        self.items = items
        self.availableSpace = availableSpace
        costs = Array(repeating: .infinity, count: items.count + 1)
        breaks = Array(repeating: nil, count: items.count + 1)
        sizeCache = SegmentSizingCache(items: items, availableSpace: availableSpace)
    }

    @usableFromInline
    mutating func solve() -> LineBreakingOutput {
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
                // start values) also won't fit: overflow only grows, and structural
                // violations (line-break / shouldStartInNewLine at non-first position)
                // move further from position 0 as start decreases.
                if range.count > 1 { break }
                continue
            }
            if candidateCost < costs[end] {
                costs[end] = candidateCost
                breaks[end] = start
            }
        }
    }

    private mutating func candidateCost(for range: Range<Int>) -> CGFloat? {
        guard let penalties = penalties(for: range) else {
            return nil
        }
        return costs[range.lowerBound] + penalties.space + penalties.stretch + lineCountBias(for: range.lowerBound)
    }

    private mutating func penalties(for range: Range<Int>) -> (space: CGFloat, stretch: CGFloat)? {
        if let calculation = sizeCache.calculation(for: range) {
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

    private func stretchPenalty(for calculation: SizeCalculation, in range: Range<Int>) -> CGFloat {
        zip(range, calculation.items).sum { index, output in
            let deviation = output.size - items[index].size.lowerBound
            return deviation * deviation
        }
    }

    private func overflowPenalty(for item: LineItemInput) -> CGFloat? {
        let overflow = item.size.lowerBound - availableSpace
        return overflow > 0 ? overflow : nil
    }

    private mutating func rebuildLines() -> LineBreakingOutput {
        var result: LineBreakingOutput = []
        var end = items.count
        while let start = breaks[end] {
            let range = start ..< end
            let line = sizeCache.calculation(for: range)?.items ?? sizeCache.fallbackLineOutput(for: range)
            result.append(line)
            end = start
        }
        result.reverse()
        return result
    }
}

@usableFromInline
struct SegmentSizingCache {
    let items: LineBreakingInput
    let availableSpace: CGFloat
    private var computed: Set<Range<Int>> = []
    private var calculations: [Range<Int>: SizeCalculation] = [:]

    @usableFromInline
    init(items: LineBreakingInput, availableSpace: CGFloat) {
        self.items = items
        self.availableSpace = availableSpace
    }

    mutating func calculation(for range: Range<Int>) -> SizeCalculation? {
        if computed.contains(range) {
            return calculations[range]
        }
        let result = sizes(of: indexedItems(in: range), availableSpace: availableSpace)
        computed.insert(range)
        calculations[range] = result
        return result
    }

    func fallbackLineOutput(for range: Range<Int>) -> LineOutput {
        fallbackLine(indexedItems(in: range))
    }

    private func indexedItems(in range: Range<Int>) -> IndexedLineBreakingInput {
        range.map { ($0, items[$0]) }
    }
}

// MARK: - Line sizing

/// Places items at their minimum sizes when the normal sizing constraints cannot be satisfied
/// (e.g. an item wider than the available space).
@inlinable
func fallbackLine(_ items: IndexedLineBreakingInput) -> LineOutput {
    items.enumerated().map { i, item in
        LineItemOutput(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
    }
}

@usableFromInline
func resolvedLine(
    _ items: IndexedLineBreakingInput,
    availableSpace: CGFloat
) -> LineOutput {
    sizes(of: items, availableSpace: availableSpace)?.items ?? fallbackLine(items)
}

@usableFromInline
typealias SizeCalculation = (items: LineOutput, remainingSpace: CGFloat)

@inlinable
func sizes(of items: IndexedLineBreakingInput, availableSpace: CGFloat) -> SizeCalculation? {
    guard let items = normalizedItemsForSizing(items) else {
        return nil
    }

    let totalMinimumSize = totalMinimumSize(of: items)
    guard totalMinimumSize <= availableSpace + roundingTolerance(for: totalMinimumSize, availableSpace: availableSpace) else {
        return nil
    }

    var remainingSpace = max(0, availableSpace - totalMinimumSize)
    guard maximumFlexItemsFit(items, availableSpace: availableSpace, remainingSpace: remainingSpace) else {
        return nil
    }

    let result = distributeRemainingSpace(in: items, remainingSpace: &remainingSpace)
    return SizeCalculation(items: result, remainingSpace: remainingSpace)
}

@usableFromInline
func normalizedItemsForSizing(_ items: IndexedLineBreakingInput) -> IndexedLineBreakingInput? {
    guard !items.isEmpty else {
        return nil
    }

    let positionOfLineBreak = items.lastIndex(where: \.element.isLineBreakView)
    if let positionOfLineBreak, positionOfLineBreak > 0 {
        return nil
    }

    if items.dropFirst().contains(where: \.element.shouldStartInNewLine) {
        return nil
    }

    var normalized = items
    if let positionOfLineBreak {
        let afterLineBreak = normalized.index(after: positionOfLineBreak)
        if afterLineBreak < normalized.endIndex {
            normalized[afterLineBreak].element.spacing = 0
        }
    }
    return normalized
}

@usableFromInline
func totalMinimumSize(of items: IndexedLineBreakingInput) -> CGFloat {
    items.sum(of: \.element.size.lowerBound) + items.dropFirst().sum(of: \.element.spacing)
}

@usableFromInline
func roundingTolerance(for totalMinimumSize: CGFloat, availableSpace: CGFloat) -> CGFloat {
    max(totalMinimumSize.magnitude, availableSpace.magnitude, 1) * CGFloat.ulpOfOne
}

@usableFromInline
func maximumFlexItemsFit(
    _ items: IndexedLineBreakingInput,
    availableSpace: CGFloat,
    remainingSpace: CGFloat
) -> Bool {
    // Each `.maximum` item wants to grow toward filling the line; account for their
    // growth cumulatively so several of them on one segment cannot each claim the
    // same remaining space independently.
    var remainingForMaximumItems = remainingSpace
    for item in items where item.element.flexibility == .maximum {
        let size = max(item.element.size.lowerBound, min(availableSpace, item.element.size.upperBound))
        let growth = size - item.element.size.lowerBound
        if growth > remainingForMaximumItems {
            return false
        }
        remainingForMaximumItems -= growth
    }
    return true
}

@usableFromInline
func distributeRemainingSpace(
    in items: IndexedLineBreakingInput,
    remainingSpace: inout CGFloat
) -> LineOutput {
    // Layout according to priorities and proportionally distribute remaining space
    // between flexible views.
    var result = items.enumerated().map { i, item in
        LineItemOutput(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
    }

    let itemsInPriorityOrder = Dictionary(grouping: items.enumerated(), by: \.element.element.priority)
    let priorities = itemsInPriorityOrder.keys.sorted(by: >)
    for priority in priorities where remainingSpace > 0 {
        let items = itemsInPriorityOrder[priority] ?? []
        let itemsInFlexibilityOrder = items.sorted(using: KeyPathComparator(\.element.element.growingPotential))
        var remainingItemCount = items.count
        for (index, item) in itemsInFlexibilityOrder {
            let offer = remainingSpace / CGFloat(remainingItemCount)
            let allocation = min(item.element.growingPotential, offer)
            result[index].size += allocation
            remainingSpace -= allocation
            remainingItemCount -= 1
        }
    }
    return result
}
