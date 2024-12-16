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
        if flexibility == .minimum {
            return 0
        } else {
            return size.upperBound - size.lowerBound
        }
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
            } else if let line = sizes(of: currentLine, availableSpace: availableSpace)?.items {
                lines.append(line)
                currentLine = [item]
            }
        }
        if let line = sizes(of: currentLine, availableSpace: availableSpace)?.items {
            lines.append(line)
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

        for end in 1 ... count {
            for start in (0 ..< end).reversed() {
                let itemsToEvaluate: IndexedLineBreakingInput = (start ..< end).map { ($0, items[$0]) }
                guard let calculation = sizes(of: itemsToEvaluate, availableSpace: availableSpace) else { continue }
                let remainingSpace = calculation.remainingSpace
                let spacePenalty = remainingSpace * remainingSpace
                let stretchPenalty = zip(itemsToEvaluate, calculation.items).sum { item, calculation in
                    let deviation = calculation.size - item.element.size.lowerBound
                    return deviation * deviation
                }
                let bias = CGFloat(count - start) * 10 // Introduce a small bias to prefer breaks that fill earlier lines more
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
            let line = sizes(of: (start..<end).map { ($0, items[$0]) }, availableSpace: availableSpace)?.items ?? (start..<end).map { index in
                LineItemOutput(
                    index: index,
                    size: items[index].size.lowerBound,
                    leadingSpace: index == start ? 0 : items[index].spacing
                )
            }
            result.insert(line, at: 0)
            end = start
        }
        return result
    }
}

@usableFromInline
typealias SizeCalculation = (items: LineOutput, remainingSpace: CGFloat)

@inlinable
func sizes(of items: IndexedLineBreakingInput, availableSpace: CGFloat) -> SizeCalculation? {
    if items.isEmpty {
        return nil
    }
    let positionOfLineBreak = items.lastIndex(where: \.element.isLineBreakView)
    if let positionOfLineBreak, positionOfLineBreak > 0 {
        return nil
    }
    let numberOfExpandedItems = items.count { $0.element.flexibility == .maximum }
    switch numberOfExpandedItems {
    case 0:
        break
    case 1 where items.count == 1:
        let size = max(items[0].element.size.lowerBound, min(availableSpace, items[0].element.size.upperBound))
        return SizeCalculation(items: [LineItemOutput(index: items[0].offset, size: size, leadingSpace: 0)], remainingSpace: 0)
    default:
        return nil
    }

    let numberOfNewLines = items.count(where: \.element.shouldStartInNewLine)
    if numberOfNewLines > 1 {
        return nil
    } else if numberOfNewLines == 1, !items[0].element.shouldStartInNewLine {
        return nil
    }

    let totalSizeOfItems = items.sum(of: \.element.size.lowerBound) + items.dropFirst().sum(of: \.element.spacing)
    if totalSizeOfItems > availableSpace {
        return nil
    }

    var result: LineOutput = items.map { LineItemOutput(index: $0.offset, size: $0.element.size.lowerBound, leadingSpace: $0.element.spacing) }
    result[0].leadingSpace = 0
    if let positionOfLineBreak, case let afterLineBreak = items.index(after: positionOfLineBreak), afterLineBreak < items.endIndex {
        result[afterLineBreak].leadingSpace = 0
    }
    var remainingSpace = availableSpace - totalSizeOfItems
    let itemsInPriorityOrder = Dictionary(grouping: items.enumerated(), by: \.element.element.priority)
    let priorities = itemsInPriorityOrder.keys.sorted(by: >)
    for priority in priorities where remainingSpace > 0 {
        let items = itemsInPriorityOrder[priority] ?? []
        let itemsInFlexibilityOrder = items.sorted(using: KeyPathComparator(\.element.element.growingPotential))
        var remainingItemCount = items.count
        let potentialGrowth = min(items.sum(of: \.element.element.growingPotential), remainingSpace)
        for (index, item) in itemsInFlexibilityOrder {
            let offer = potentialGrowth / CGFloat(remainingItemCount)
            let allocation = min(item.element.growingPotential, offer)
            result[index].size += allocation
            remainingSpace -= allocation
            remainingItemCount -= 1
        }
    }
    return SizeCalculation(items: result, remainingSpace: remainingSpace)
}
