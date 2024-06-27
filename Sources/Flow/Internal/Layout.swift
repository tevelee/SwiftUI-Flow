import CoreFoundation
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct FlowLayout {
    let axis: Axis
    var itemSpacing: CGFloat?
    var lineSpacing: CGFloat?
    var reversedBreadth: Bool = false
    var alternatingReversedBreadth: Bool = false
    var reversedDepth: Bool = false
    var justification: Justification?
    var distributeItemsEvenly: Bool
    let align: (Dimensions) -> CGFloat

    private struct ItemWithSpacing<T> {
        var item: T
        var size: Size
        var spacing: CGFloat = 0

        mutating func append(_ item: Item, size: Size, spacing: CGFloat) where Self == ItemWithSpacing<Line> {
            self.item.append(.init(item: item, size: size, spacing: spacing))
            self.size = Size(breadth: self.size.breadth + spacing + size.breadth, depth: max(self.size.depth, size.depth))
        }
    }

    private typealias Item = (subview: Subview, cache: FlowLayoutCache.SubviewCache)
    private typealias Line = [ItemWithSpacing<Item>]
    private typealias Lines = [ItemWithSpacing<Line>]

    func sizeThatFits(
        proposal proposedSize: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let lines = calculateLayout(in: proposedSize, of: subviews, cache: cache)
        let spacings = lines.map(\.spacing).reduce(into: 0, +=)
        let size = lines
            .map(\.size)
            .reduce(.zero, breadth: max, depth: +)
            .adding(spacings, on: .vertical)
        return CGSize(size: size, axis: axis)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) {
        guard !subviews.isEmpty else { return }

        var reversedBreadth = self.reversedBreadth
        var target = bounds.origin.size(on: axis)
        let lines = calculateLayout(in: proposal, of: subviews, cache: cache)
        for line in lines {
            if reversedDepth {
                target.depth -= line.size.depth + line.spacing
            } else {
                target.depth += line.spacing
            }
            if reversedBreadth {
                target.breadth = switch axis {
                    case .horizontal: bounds.maxX
                    case .vertical: bounds.maxY
                }
            } else {
                target.breadth = switch axis {
                    case .horizontal: bounds.minX
                    case .vertical: bounds.minY
                }
            }
            for item in line.item {
                if reversedBreadth {
                    target.breadth -= item.size.breadth + item.spacing
                } else {
                    target.breadth += item.spacing
                }
                alignAndPlace(item, in: line, at: target)
                if !reversedBreadth {
                    target.breadth += item.size.breadth
                }
            }
            if alternatingReversedBreadth {
                reversedBreadth.toggle()
            }
            if !reversedDepth {
                target.depth += line.size.depth
            }
        }
    }

    func makeCache(_ subviews: some Subviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: axis)
    }

    private func alignAndPlace(
        _ item: Line.Element,
        in line: Lines.Element,
        at placement: Size
    ) {
        var placement = placement
        let proposedSize = ProposedViewSize(size: Size(breadth: item.size.breadth, depth: line.size.depth), axis: axis)
        let depth = item.size.depth
        if depth > 0 {
            placement.depth += (align(item.item.subview.dimensions(proposedSize)) / depth) * (line.size.depth - depth)
        }
        item.item.subview.place(at: .init(size: placement, axis: axis), anchor: .topLeading, proposal: proposedSize)
    }

    private func calculateLayout(
        in proposedSize: ProposedViewSize,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> Lines {
        var lines: Lines = []
        let proposedBreadth = proposedSize.replacingUnspecifiedDimensions().value(on: axis)

        let sizes = cache.subviewsCache.map(\.ideal)
        let spacings = if let itemSpacing {
            [0] + Array(repeating: itemSpacing, count: subviews.count - 1)
        } else {
            [0] + cache.subviewsCache.adjacentPairs().map { lhs, rhs in
                lhs.spacing.distance(to: rhs.spacing, along: axis)
            }
        }

        for index in subviews.indices {
            let (subview, size, spacing, cache) = (subviews[index], sizes[index], spacings[index], cache.subviewsCache[index])
            if let lastIndex = lines.indices.last {
                let additionalBreadth = spacing + size.breadth
                if lines[lastIndex].size.breadth + additionalBreadth <= proposedBreadth {
                    lines[lastIndex].append((subview, cache), size: size, spacing: spacing)
                    continue
                }
            }
            lines.append(.init(item: [.init(item: (subview: subview, cache: cache), size: size)], size: size))
        }
        distributeItems(in: &lines, proposedSize: proposedSize, subviews: subviews, sizes: sizes, spacings: spacings, cache: cache)
        updateFlexibleItems(in: &lines, proposedSize: proposedSize)
        updateLineSpacings(in: &lines)
        return lines
    }

    private func distributeItems(
        in lines: inout Lines,
        proposedSize: ProposedViewSize,
        subviews: some Subviews,
        sizes: [Size],
        spacings: [CGFloat],
        cache: FlowLayoutCache
    ) {
        guard distributeItemsEvenly else { return }

        // Knuth-Plass Line Breaking Algorithm
        let proposedBreadth = proposedSize.replacingUnspecifiedDimensions().value(on: axis)
        let count = sizes.count
        var costs: [CGFloat] = Array(repeating: .infinity, count: count + 1)
        var breaks: [Int?] = Array(repeating: nil, count: count + 1)

        costs[0] = 0

        for end in 0 ..< count {
            var totalBreadth: CGFloat = 0
            for start in stride(from: end, through: 0, by: -1) {
                let size = sizes[start].breadth
                let spacing = start > 0 && start < end ? spacings[start] : 0
                totalBreadth += size + spacing
                if totalBreadth > proposedBreadth {
                    break
                }
                let remainingSpace = proposedBreadth - totalBreadth
                let penalty = abs(totalBreadth - (proposedBreadth / CGFloat(end - start + 1))) * 2
                let cost = costs[start] + remainingSpace * remainingSpace + penalty
                if cost < costs[end + 1] {
                    costs[end + 1] = cost
                    breaks[end + 1] = start
                }
            }
        }

        var breakpoints: [Int] = []
        var i = count
        while let breakPoint = breaks[i], breakPoint >= 0 {
            breakpoints.insert(i, at: 0)
            i = breakPoint
        }
        breakpoints.insert(0, at: 0)

        var newLines: Lines = []
        for (start, end) in breakpoints.adjacentPairs() {
            var line: ItemWithSpacing<Line> = .init(item: [], size: .zero)
            for index in start..<end {
                let subview = subviews[index]
                let size = sizes[index]
                let spacing = index == start ? 0 : spacings[index] // Reset spacing for the first item in each line
                line.append((subview, cache.subviewsCache[index]), size: size, spacing: spacing)
            }
            newLines.append(line)
        }

        lines = newLines
    }

    private func updateFlexibleItems(in lines: inout Lines, proposedSize: ProposedViewSize) {
        guard let justification else { return }
        for index in lines.indices {
            updateFlexibleItems(in: &lines[index], proposedSize: proposedSize, justification: justification)
        }
    }

    private func updateLineSpacings(in lines: inout Lines) {
        let lineSpacings = lines.map { line in
            line.item.reduce(into: ViewSpacing()) { $0.formUnion($1.item.cache.spacing) }
        }
        for index in lines.indices.dropFirst() {
            let spacing = self.lineSpacing ?? lineSpacings[index].distance(to: lineSpacings[index.advanced(by: -1)], along: axis.perpendicular)
            lines[index].spacing = spacing
        }
    }

    private func itemSpacing<S: Subviews>(
        toPrevious index: S.Index,
        subviews: S
    ) -> CGFloat {
        guard index != subviews.startIndex else { return 0 }
        return self.itemSpacing ?? subviews[index.advanced(by: -1)].spacing.distance(to: subviews[index].spacing, along: axis)
    }

    private func updateFlexibleItems(in line: inout ItemWithSpacing<Line>, proposedSize: ProposedViewSize, justification: Justification) {
        let subviewsInPriorityOrder = line.item.enumerated().map { offset, subview in
            SubviewProperties(indexInLine: offset, spacing: subview.spacing, cache: subview.item.cache)
        }.sorted(using: [KeyPathComparator(\.cache.priority), KeyPathComparator(\.flexibility), KeyPathComparator(\.cache.ideal.breadth)])

        let sumOfIdeal = subviewsInPriorityOrder.map { $0.spacing + $0.cache.ideal.breadth }.reduce(into: 0, +=)
        var remainingSpace = proposedSize.value(on: axis) - sumOfIdeal
        let count = line.item.count

        if case .stretchSpaces = justification {
            let distributedSpace = remainingSpace / Double(count - 1)
            for index in line.item.indices.dropFirst() {
                line.item[index].spacing += distributedSpace
                remainingSpace -= distributedSpace
            }
        } else {
            let sumOfMax = subviewsInPriorityOrder.map { $0.spacing + $0.cache.max.breadth }.reduce(into: 0, +=)
            let potentialGrowth = sumOfMax - sumOfIdeal
            if potentialGrowth <= remainingSpace {
                for subview in subviewsInPriorityOrder {
                    line.item[subview.indexInLine].size.breadth = subview.cache.max.breadth
                    remainingSpace -= subview.flexibility
                }
            } else {
                var remainingItemCount = count
                for subview in subviewsInPriorityOrder {
                    let offer = remainingSpace / Double(remainingItemCount)
                    let actual = min(subview.flexibility, offer)
                    remainingSpace -= actual
                    remainingItemCount -= 1
                    line.item[subview.indexInLine].size.breadth += actual
                }
            }
            if case .stretchItemsAndSpaces = justification {
                let distributedSpace = remainingSpace / Double(count - 1)
                for index in line.item.indices.dropFirst() {
                    line.item[index].spacing += distributedSpace
                    remainingSpace -= distributedSpace
                }
            }
        }
        line.size.breadth = proposedSize.value(on: axis) - remainingSpace
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension FlowLayout: Layout {
    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        makeCache(subviews)
    }

    static func vertical(
        alignment: HorizontalAlignment,
        itemSpacing: CGFloat?,
        lineSpacing: CGFloat?,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        .init(
            axis: .vertical,
            itemSpacing: itemSpacing,
            lineSpacing: lineSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        ) {
            $0[alignment]
        }
    }

    static func horizontal(
        alignment: VerticalAlignment,
        itemSpacing: CGFloat?,
        lineSpacing: CGFloat?,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        .init(
            axis: .horizontal,
            itemSpacing: itemSpacing,
            lineSpacing: lineSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        ) {
            $0[alignment]
        }
    }
}

private extension Array where Element == Size {
    func reduce(
        _ initial: Size,
        breadth: (CGFloat, CGFloat) -> CGFloat,
        depth: (CGFloat, CGFloat) -> CGFloat
    ) -> Size {
        reduce(initial) { result, size in
            Size(
                breadth: breadth(result.breadth, size.breadth),
                depth: depth(result.depth, size.depth)
            )
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct SubviewProperties {
    var indexInLine: Int
    var spacing: Double
    var cache: FlowLayoutCache.SubviewCache
    var flexibility: Double { cache.max.breadth - cache.ideal.breadth }
}

private extension Sequence {
    func adjacentPairs() -> some Sequence<(Element, Element)> {
        zip(self, self.dropFirst())
    }
}
