import CoreFoundation
import SwiftUI

@usableFromInline
struct FlowLayout: Sendable {
    let axis: Axis
    var itemSpacing: CGFloat?
    var lineSpacing: CGFloat?
    var reversedBreadth: Bool = false
    var alternatingReversedBreadth: Bool = false
    var reversedDepth: Bool = false
    var justification: Justification?
    var distributeItemsEvenly: Bool
    let align: @Sendable (Dimensions) -> CGFloat

    private struct ItemWithSpacing<T> {
        var item: T
        var size: Size
        var leadingSpace: CGFloat = 0

        mutating func append(_ item: Item, size: Size, spacing: CGFloat) where Self == ItemWithSpacing<Line> {
            self.item.append(.init(item: item, size: size, leadingSpace: spacing))
            self.size = Size(breadth: self.size.breadth + spacing + size.breadth, depth: max(self.size.depth, size.depth))
        }
    }

    private typealias Item = (subview: Subview, cache: FlowLayoutCache.SubviewCache)
    private typealias Line = [ItemWithSpacing<Item>]
    private typealias Lines = [ItemWithSpacing<Line>]

    @usableFromInline
    func sizeThatFits(
        proposal proposedSize: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let lines = calculateLayout(in: proposedSize, of: subviews, cache: cache)
        var size = lines
            .map(\.size)
            .reduce(.zero, breadth: max, depth: +)
        size[.vertical] += lines.sum(of: \.leadingSpace)
        return CGSize(size: size, axis: axis)
    }

    @usableFromInline
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) {
        guard !subviews.isEmpty else { return }

        var target = bounds.origin.size(on: axis)
        var reversedBreadth = self.reversedBreadth

        let lines = calculateLayout(in: proposal, of: subviews, cache: cache)

        for line in lines {
            adjust(&target, for: line, on: .vertical, reversed: reversedDepth) { target in
                target.breadth = reversedBreadth ? bounds.maximumValue(on: axis) : bounds.minimumValue(on: axis)

                for item in line.item {
                    adjust(&target, for: item, on: .horizontal, reversed: reversedBreadth) { target in
                        alignAndPlace(item, in: line, at: target)
                    }
                }

                if alternatingReversedBreadth {
                    reversedBreadth.toggle()
                }
            }
        }
    }

    @usableFromInline
    func makeCache(_ subviews: some Subviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: axis)
    }

    private func adjust<T>(
        _ target: inout Size,
        for item: ItemWithSpacing<T>,
        on axis: Axis,
        reversed: Bool,
        body: (inout Size) -> Void
    ) {
        let leadingSpace = item.leadingSpace
        let size = item.size[axis]
        target[axis] += reversed ? -leadingSpace-size : leadingSpace
        body(&target)
        target[axis] += reversed ? 0 : size
    }

    private func alignAndPlace(
        _ item: Line.Element,
        in line: Lines.Element,
        at placement: Size
    ) {
        var placement = placement
        let size = Size(breadth: item.size.breadth, depth: line.size.depth)
        let proposedSize = ProposedViewSize(size: size, axis: axis)
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
        let sizes = cache.subviewsCache.map(\.ideal)
        let spacings = if let itemSpacing {
            [0] + Array(repeating: itemSpacing, count: subviews.count - 1)
        } else {
            [0] + cache.subviewsCache.adjacentPairs().map { lhs, rhs in
                lhs.spacing.distance(to: rhs.spacing, along: axis)
            }
        }

        let lineBreaker: LineBreaking = if distributeItemsEvenly {
            KnuthPlassLineBreaker()
        } else {
            FlowLineBreaker()
        }

        let breakpoints = lineBreaker.wrapItemsToLines(
            sizes: sizes.map(\.breadth),
            spacings: spacings,
            in: proposedSize.replacingUnspecifiedDimensions(by: .infinity).value(on: axis)
        )

        var lines: Lines = []
        for (start, end) in breakpoints.adjacentPairs() {
            var line = ItemWithSpacing<Line>(item: [], size: .zero)
            for index in start ..< end {
                let subview = subviews[index]
                let size = sizes[index]
                let spacing = index == start ? 0 : spacings[index] // Reset spacing for the first item in each line
                line.append((subview, cache.subviewsCache[index]), size: size, spacing: spacing)
            }
            lines.append(line)
        }
        updateFlexibleItems(in: &lines, proposedSize: proposedSize)
        updateLineSpacings(in: &lines)
        return lines
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
            lines[index].leadingSpace = spacing
        }
    }

    private func itemSpacing<S: Subviews>(
        toPrevious index: S.Index,
        subviews: S
    ) -> CGFloat {
        guard index != subviews.startIndex else { return 0 }
        return self.itemSpacing ?? subviews[index.advanced(by: -1)].spacing.distance(to: subviews[index].spacing, along: axis)
    }

    private func updateFlexibleItems(
        in line: inout ItemWithSpacing<Line>,
        proposedSize: ProposedViewSize,
        justification: Justification
    ) {
        let subviewsInPriorityOrder = line.item.enumerated()
            .map { offset, subview in
                SubviewProperties(
                    indexInLine: offset,
                    spacing: subview.leadingSpace,
                    cache: subview.item.cache
                )
            }
            .sorted(using: [
                KeyPathComparator(\.cache.priority),
                KeyPathComparator(\.flexibility),
                KeyPathComparator(\.cache.ideal.breadth)
            ])

        let count = line.item.count
        let sumOfIdeal = subviewsInPriorityOrder.sum { $0.spacing + $0.cache.ideal.breadth }
        var remainingSpace = proposedSize.value(on: axis) - sumOfIdeal

        if justification.isStretchingItems {
            let sumOfMax = subviewsInPriorityOrder.sum { $0.spacing + $0.cache.max.breadth }
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
        }
        
        if justification.isStretchingSpaces {
            let distributedSpace = remainingSpace / Double(count - 1)
            for index in line.item.indices.dropFirst() {
                line.item[index].leadingSpace += distributedSpace
                remainingSpace -= distributedSpace
            }
        }
        
        line.size.breadth = proposedSize.value(on: axis) - remainingSpace
    }
}

extension FlowLayout: Layout {
    @usableFromInline
    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        makeCache(subviews)
    }

    @usableFromInline
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

    @usableFromInline
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

extension Array where Element == Size {
    @inlinable
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

private struct SubviewProperties {
    var indexInLine: Int
    var spacing: Double
    var cache: FlowLayoutCache.SubviewCache
    var flexibility: Double { cache.max.breadth - cache.ideal.breadth }
}
