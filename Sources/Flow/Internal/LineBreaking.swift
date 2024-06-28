import CoreFoundation

@usableFromInline
protocol LineBreaking {
    @inlinable
    func wrapItemsToLines(sizes: [CGFloat], spacings: [CGFloat], in availableSpace: CGFloat) -> [Int]
}

@usableFromInline
struct FlowLineBreaker: LineBreaking {
    @inlinable
    func wrapItemsToLines(sizes: [CGFloat], spacings: [CGFloat], in availableSpace: CGFloat) -> [Int] {
        var breakpoints: [Int] = []
        var currentLineSize: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            let requiredSpace = spacings[index] + size
            if currentLineSize + requiredSpace > availableSpace {
                breakpoints.append(index)
                currentLineSize = size
            } else {
                currentLineSize += requiredSpace
            }
        }

        if breakpoints.first != 0 {
            breakpoints.insert(0, at: 0)
        }
        breakpoints.append(sizes.endIndex)

        return breakpoints
    }
}

@usableFromInline
struct KnuthPlassLineBreaker: LineBreaking {
    @inlinable
    func wrapItemsToLines(sizes: [CGFloat], spacings: [CGFloat], in availableSpace: CGFloat) -> [Int] {
        let count = sizes.count
        var costs: [CGFloat] = Array(repeating: .infinity, count: count + 1)
        var breaks: [Int?] = Array(repeating: nil, count: count + 1)

        costs[0] = 0

        for end in 1 ... count {
            var totalBreadth: CGFloat = 0
            for start in (0 ..< end).reversed() {
                let size = sizes[start]
                let spacing = (end - start) == 1 ? 0 : spacings[start + 1]
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
            return Array(0 ... sizes.endIndex)
        }

        var breakpoints: [Int] = []
        var i = sizes.count
        while let breakPoint = breaks[i] {
            breakpoints.insert(i, at: 0)
            i = breakPoint
        }
        breakpoints.insert(0, at: 0)
        return breakpoints
    }
}
