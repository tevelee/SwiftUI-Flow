import CoreFoundation
import Foundation

@usableFromInline
struct LineItemInput {
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
            if sizes(of: currentLine + [item], availableSpace: availableSpace) != nil {
                currentLine.append(item)
            } else {
                if !currentLine.isEmpty {
                    lines.append(sizes(of: currentLine, availableSpace: availableSpace)?.items ?? fallbackLine(currentLine))
                }
                currentLine = [item]
            }
        }
        if !currentLine.isEmpty {
            lines.append(sizes(of: currentLine, availableSpace: availableSpace)?.items ?? fallbackLine(currentLine))
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
        if items.isEmpty {
            return []
        }
        let count = items.count
        var costs: [CGFloat] = Array(repeating: .infinity, count: count + 1)
        var breaks: [Int?] = Array(repeating: nil, count: count + 1)

        costs[0] = 0

        // Memoize segment sizing: each `start ..< end` segment is sized once during the
        // dynamic-programming sweep and reused when backtracking the chosen breaks.
        var sizeCache: [Range<Int>: SizeCalculation?] = [:]
        func cachedSizes(_ range: Range<Int>) -> SizeCalculation? {
            if let cached = sizeCache[range] {
                return cached
            }
            let segment: IndexedLineBreakingInput = range.map { ($0, items[$0]) }
            let computed = sizes(of: segment, availableSpace: availableSpace)
            sizeCache[range] = computed
            return computed
        }

        for end in 1 ... count {
            for start in (0 ..< end).reversed() {
                let spacePenalty: CGFloat
                let stretchPenalty: CGFloat
                if let calculation = cachedSizes(start ..< end) {
                    let remaining = calculation.remainingSpace
                    spacePenalty = remaining * remaining
                    stretchPenalty = zip(start ..< end, calculation.items).sum { index, output in
                        let deviation = output.size - items[index].size.lowerBound
                        return deviation * deviation
                    }
                } else if end == start + 1 {
                    // Single item that exceeds the available space: allow it on its own line
                    // with an overflow penalty so it is only chosen as a last resort.
                    let overflow = items[start].size.lowerBound - availableSpace
                    guard overflow > 0 else { continue }
                    spacePenalty = overflow * overflow
                    stretchPenalty = 0
                } else {
                    continue
                }
                // Bias toward fewer lines: every chosen break contributes this term, and
                // earlier break points (smaller `start`, i.e. more items deferred to later
                // lines) contribute more, nudging the solver to fill earlier lines first.
                // The weight is a heuristic kept small relative to the squared space/stretch
                // penalties so it mainly breaks ties between otherwise comparable layouts.
                let bias = CGFloat(count - start) * 5
                let cost = costs[start] + spacePenalty + stretchPenalty + bias
                if cost < costs[end] {
                    costs[end] = cost
                    breaks[end] = start
                }
            }
        }

        var result: LineBreakingOutput = []
        var end = items.count
        while let start = breaks[end] {
            let line = cachedSizes(start ..< end)?.items ?? fallbackLine((start ..< end).map { ($0, items[$0]) })
            result.insert(line, at: 0)
            end = start
        }
        return result
    }
}

/// Places items at their minimum sizes when the normal sizing constraints cannot be satisfied
/// (e.g. an item wider than the available space).
@inlinable
func fallbackLine(_ items: IndexedLineBreakingInput) -> LineOutput {
    items.enumerated().map { i, item in
        LineItemOutput(index: item.offset, size: item.element.size.lowerBound, leadingSpace: i == 0 ? 0 : item.element.spacing)
    }
}

@usableFromInline
typealias SizeCalculation = (items: LineOutput, remainingSpace: CGFloat)

@inlinable
func sizes(of items: IndexedLineBreakingInput, availableSpace: CGFloat) -> SizeCalculation? {
    if items.isEmpty {
        return nil
    }
    // Handle line break view
    let positionOfLineBreak = items.lastIndex(where: \.element.isLineBreakView)
    if let positionOfLineBreak, positionOfLineBreak > 0 {
        return nil
    }
    var items = items
    if let positionOfLineBreak, case let afterLineBreak = items.index(after: positionOfLineBreak), afterLineBreak < items.endIndex {
        items[afterLineBreak].element.spacing = 0
    }
    // Handle manual new line modifier
    let numberOfNewLines = items.filter(\.element.shouldStartInNewLine).count
    if numberOfNewLines > 1 {
        return nil
    } else if numberOfNewLines == 1, !items[0].element.shouldStartInNewLine {
        return nil
    }
    // Calculate total size
    let totalSizeOfItems = items.sum(of: \.element.size.lowerBound) + items.dropFirst().sum(of: \.element.spacing)
    let roundingTolerance = max(totalSizeOfItems.magnitude, availableSpace.magnitude, 1) * CGFloat.ulpOfOne
    if totalSizeOfItems > availableSpace + roundingTolerance {
        return nil
    }
    // Clamp to zero: within the tolerance above the leftover can be a tiny negative.
    var remainingSpace = max(0, availableSpace - totalSizeOfItems)
    // Handle expanded items. Each `.maximum` item wants to grow toward filling the
    // line; account for their growth cumulatively so several of them on one segment
    // can't each independently claim the same remaining space.
    var remainingForMaximumItems = remainingSpace
    for item in items where item.element.flexibility == .maximum {
        let size = max(item.element.size.lowerBound, min(availableSpace, item.element.size.upperBound))
        let growth = size - item.element.size.lowerBound
        if growth > remainingForMaximumItems {
            return nil
        }
        remainingForMaximumItems -= growth
    }
    // Layout according to priorities and proportionally distribute remaining space between flexible views
    var result: LineOutput = items.map { LineItemOutput(index: $0.offset, size: $0.element.size.lowerBound, leadingSpace: $0.element.spacing) }
    result[0].leadingSpace = 0
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
    return SizeCalculation(items: result, remainingSpace: remainingSpace)
}
