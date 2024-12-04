import CoreFoundation
import Foundation

@usableFromInline
struct LineItem {
    @usableFromInline
    let subview: any Subview
    @usableFromInline
    let cache: FlowLayoutCache.SubviewCache
    @usableFromInline
    let size: ClosedRange<CGFloat>
    @usableFromInline
    let spacing: CGFloat
    @inlinable
    var flexibility: Double {
        if cache.layoutValues.flexibility.canGrow {
            return cache.max.breadth - cache.ideal.breadth
        } else {
            return 0
        }
    }

    @inlinable
    func requiresNewLine(availableSpace: CGFloat) -> Bool {
        cache.layoutValues.shouldStartInNewLine || (cache.layoutValues.flexibility == .expanded && size.upperBound >= availableSpace)
    }
}

@usableFromInline
protocol LineBreaking {
    @inlinable
    func wrapItemsToLines(items: [LineItem], in availableSpace: CGFloat) -> [Line]
}

@usableFromInline
typealias Line = [(size: CGFloat, leadingSpace: CGFloat, item: LineItem)]

@usableFromInline
struct FlowLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [LineItem], in availableSpace: CGFloat) -> [Line] {
        var currentLine: Line = []
        var lines: [Line] = []
        var currentLineSize: CGFloat = 0

        for (index, item) in items.enumerated() {
            let spacing = items[index].spacing
            let requiredSpaceForItem = item.size.lowerBound
            let availableSpaceInRow = availableSpace - currentLineSize - spacing
            let maximumSpaceForItem = min(item.size.upperBound, availableSpaceInRow)
            var computedSpacing: CGFloat = spacing
            if currentLineSize + spacing + requiredSpaceForItem > availableSpace || item.requiresNewLine(availableSpace: availableSpaceInRow) {
                lines.append(currentLine)
                currentLine = []
                currentLineSize = 0
                computedSpacing = 0
            }
            let computedSize: CGFloat
            switch item.cache.layoutValues.flexibility {
            case .compactRigid, .compactFlexible:
                computedSize = requiredSpaceForItem
            case .natural, .expanded:
                let availableSpaceInRow = availableSpace - currentLineSize - spacing
                let maximumSpaceForItem = min(item.size.upperBound, availableSpaceInRow)
                computedSize = maximumSpaceForItem
            }
            currentLine.append((computedSize, computedSpacing, item))
            currentLineSize += computedSpacing + computedSize
        }
        lines.append(currentLine)
        return lines
    }
}

@usableFromInline
struct KnuthPlassLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [LineItem], in availableSpace: CGFloat) -> [Line] {
        if items.isEmpty {
            return []
        }
        let count = items.count
        var costs: [CGFloat] = Array(repeating: .infinity, count: count + 1)
        var breaks: [Int?] = Array(repeating: nil, count: count + 1)

        costs[0] = 0

        for end in 1 ... count {
            for start in (0 ..< end).reversed() {
                let itemsToEvaluate = (start ..< end).map { items[$0] }
                guard let calculation = sizes(of: itemsToEvaluate, availableSpace: availableSpace) else { continue }
                let remainingSpace = calculation.remainingSpace
                let spacePenalty = remainingSpace * remainingSpace
                let stretchPenalty = zip(itemsToEvaluate, calculation.items).sum { item, calculation in
                    let deviation = calculation.size - ((item.size.lowerBound + min(item.size.upperBound, availableSpace)) / 2) // Deviation from preferred size
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

        var result: [Line] = []
        var end = items.count
        while let start = breaks[end] {
            let line = sizes(of: (start..<end).map { items[$0] }, availableSpace: availableSpace)?.items ?? (start..<end).map { index in
                (size: items[index].size.lowerBound, leadingSpace: index == start ? 0 : items[index].spacing, item: items[index])
            }
            result.insert(line, at: 0)
            end = start
        }
        return result
    }
}

@usableFromInline
typealias SizeCalculation = (items: Line, remainingSpace: CGFloat)

@inlinable
func sizes(of items: [LineItem], availableSpace: CGFloat) -> SizeCalculation? {
    let numberOfExpandedItems = items.count { $0.cache.layoutValues.flexibility == .expanded }
    switch numberOfExpandedItems {
    case 0:
        break
    case 1 where items.count == 1:
        let size = max(items[0].size.lowerBound, min(availableSpace, items[0].size.upperBound))
        return SizeCalculation(items: [(size: size, leadingSpace: 0, item: items[0])], remainingSpace: 0)
    default:
        return nil
    }

    if items.isEmpty {
        return SizeCalculation(items: [], remainingSpace: availableSpace)
    }
    let totalSizeOfItems = items.sum(of: \.size.lowerBound) + items.dropFirst().sum(of: \.spacing)
    if totalSizeOfItems > availableSpace {
        return nil
    }

    var result: Line = items.map { (size: $0.size.lowerBound, leadingSpace: $0.spacing, item: $0) }
    result[0].leadingSpace = 0
    var remainingSpace = availableSpace - totalSizeOfItems
    let itemsInPriorityOrder = Dictionary(grouping: items.enumerated(), by: \.element.cache.priority)
    let priorities = itemsInPriorityOrder.keys.sorted(by: >)
    for priority in priorities where remainingSpace > 0 {
        let items = itemsInPriorityOrder[priority] ?? []
        let itemsInFlexibilityOrder = items.sorted(using: KeyPathComparator(\.element.flexibility))
        var remainingItemCount = items.count
        let potentialGrowth = min(items.sum(of: \.element.flexibility), remainingSpace)
        for (index, item) in itemsInFlexibilityOrder {
            let offer = potentialGrowth / CGFloat(remainingItemCount)
            let allocation = min(item.flexibility, offer)
            result[index].size += allocation
            remainingSpace -= allocation
            remainingItemCount -= 1
        }
    }
    return SizeCalculation(items: result, remainingSpace: remainingSpace)
}
