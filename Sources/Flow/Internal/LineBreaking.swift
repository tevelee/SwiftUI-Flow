import CoreFoundation

@inlinable
func knuthPlassLineBreakingAlgorithm(
    proposedBreadth: CGFloat,
    sizes: [Size],
    spacings: [CGFloat]
) -> [Int] {
    let breaks = calculateOptimalBreaks(
        proposedBreadth: proposedBreadth,
        sizes: sizes,
        spacings: spacings
    )

    var breakpoints: [Int] = []
    var i = sizes.count
    while let breakPoint = breaks[i] {
        breakpoints.insert(i, at: 0)
        i = breakPoint
    }
    breakpoints.insert(0, at: 0)
    return breakpoints
}

@usableFromInline
func calculateOptimalBreaks(
    proposedBreadth: CGFloat,
    sizes: [Size],
    spacings: [CGFloat]
) -> [Int?] {
    let count = sizes.count
    var costs: [CGFloat] = Array(repeating: .infinity, count: count + 1)
    var breaks: [Int?] = Array(repeating: nil, count: count + 1)

    costs[0] = 0

    for end in 1 ... count {
        var totalBreadth: CGFloat = 0
        for start in (0 ..< end).reversed() {
            let size = sizes[start].breadth
            let spacing = (end - start) == 1 ? 0 : spacings[start + 1]
            totalBreadth += size + spacing
            if totalBreadth > proposedBreadth {
                break
            }
            let remainingSpace = proposedBreadth - totalBreadth
            let bias = CGFloat(count - end) * 0.5 // Introduce a small bias to prefer breaks that fill earlier lines more
            let cost = costs[start] + remainingSpace * remainingSpace + bias
            if cost < costs[end] {
                costs[end] = cost
                breaks[end] = start
            }
        }
    }

    return breaks
}
