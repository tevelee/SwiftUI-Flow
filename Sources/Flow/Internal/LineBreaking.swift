import CoreFoundation

@usableFromInline
struct LineItem {
    @usableFromInline
    let subview: any Subview
    @usableFromInline
    let size: ClosedRange<CGFloat>
    @usableFromInline
    let spacing: CGFloat
}

@usableFromInline
protocol LineBreaking {
    @inlinable
    func wrapItemsToLines(items: [LineItem], lineBreaks: [Int], in availableSpace: CGFloat) -> [Int]
}

@usableFromInline
struct FlowLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [LineItem], lineBreaks: [Int], in availableSpace: CGFloat) -> [Int] {
        var breakpoints: [Int] = []
        var currentLineSize: CGFloat = 0

        for (index, item) in items.enumerated() {
            let requiredSpace = items[index].spacing + item.size.lowerBound
            if currentLineSize + requiredSpace > availableSpace || lineBreaks.contains(index) {
                breakpoints.append(index)
                currentLineSize = item.size.lowerBound
            } else {
                currentLineSize += requiredSpace
            }
        }

        if breakpoints.first != 0 {
            breakpoints.insert(0, at: 0)
        }
        breakpoints.append(items.endIndex)

        return breakpoints
    }
}

@usableFromInline
struct KnuthPlassLineBreaker: LineBreaking {
    @inlinable
    init() {}

    @inlinable
    func wrapItemsToLines(items: [LineItem], lineBreaks: [Int], in availableSpace: CGFloat) -> [Int] {
        if lineBreaks.isEmpty {
            return wrapItemsToLines(items: items, in: availableSpace)
        }
        var result: [Int] = []
        var start: Int = 0
        for lineBreak in lineBreaks + [items.endIndex] {
            let partial = wrapItemsToLines(
                items: Array(items[start..<lineBreak]),
                in: availableSpace
            )
            result.append(contentsOf: partial.map { $0 + start }.dropLast())
            start = lineBreak
        }
        result.append(items.endIndex)
        return result
    }

    @inlinable
    func wrapItemsToLines(items: [LineItem], in availableSpace: CGFloat) -> [Int] {
        if items.isEmpty {
            return []
        }
        let count = items.count
        var costs: [CGFloat] = Array(repeating: .infinity, count: count + 1)
        var breaks: [Int?] = Array(repeating: nil, count: count + 1)

        costs[0] = 0

        for end in 1 ... count {
            var totalBreadth: CGFloat = 0
            for start in (0 ..< end).reversed() {
                let size = items[start].size.lowerBound
                let spacing = (end - start) == 1 ? 0 : items[start + 1].spacing
                totalBreadth += size + spacing
                if totalBreadth > availableSpace {
                    break
                }
                let remainingSpace = availableSpace - totalBreadth
                let bias = CGFloat(count - end) * 0.5 // Introduce a small bias to prefer breaks that fill earlier lines more
                let cost = costs[start] + remainingSpace * remainingSpace + bias
                if cost < costs[end] {
                    costs[end] = cost
                    breaks[end] = start
                }
            }
        }

        if breaks.compactMap({ $0 }).isEmpty {
            return [0, items.endIndex]
        }

        var breakpoints: [Int] = []
        var i = items.count
        while let breakPoint = breaks[i] {
            breakpoints.insert(i, at: 0)
            i = breakPoint
        }
        breakpoints.insert(0, at: 0)
        return breakpoints
    }
}
