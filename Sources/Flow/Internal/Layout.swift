import CoreFoundation
import SwiftUI

@usableFromInline
struct FlowLayout: Sendable {
    @usableFromInline
    let axis: Axis
    @usableFromInline
    let itemSpacing: CGFloat?
    @usableFromInline
    let lineSpacing: CGFloat?
    @usableFromInline
    let reversedBreadth: Bool = false
    @usableFromInline
    let alternatingReversedBreadth: Bool = false
    @usableFromInline
    let reversedDepth: Bool = false
    @usableFromInline
    let justification: Justification?
    @usableFromInline
    let distributeItemsEvenly: Bool
    @usableFromInline
    let alignmentOnBreadth: @Sendable (any Dimensions) -> CGFloat
    @usableFromInline
    let alignmentOnDepth: @Sendable (any Dimensions) -> CGFloat

    @inlinable
    init(
        axis: Axis,
        itemSpacing: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false,
        alignmentOnBreadth: @escaping @Sendable (any Dimensions) -> CGFloat,
        alignmentOnDepth: @escaping @Sendable (any Dimensions) -> CGFloat
    ) {
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.justification = justification
        self.distributeItemsEvenly = distributeItemsEvenly
        self.alignmentOnBreadth = alignmentOnBreadth
        self.alignmentOnDepth = alignmentOnDepth
    }

    private struct ItemWithSpacing<T> {
        var item: T
        var size: Size
        var leadingSpace: CGFloat = 0
    }

    private typealias Item = (subview: any Subview, cache: FlowLayoutCache.SubviewCache)
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
        size.depth += lines.sum(of: \.leadingSpace)
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
        at target: Size
    ) {
        var position = target
        let lineDepth = line.size.depth
        let size = Size(breadth: item.size.breadth, depth: lineDepth)
        let proposedSize = ProposedViewSize(size: size, axis: axis)
        let itemDepth = item.size.depth
        if itemDepth > 0 {
            let dimensions = item.item.subview.dimensions(proposedSize)
            let alignedPosition = alignmentOnDepth(dimensions)
            position.depth += (alignedPosition / itemDepth) * (lineDepth - itemDepth)
        }
        let point = CGPoint(size: position, axis: axis)
        item.item.subview.place(at: point, anchor: .topLeading, proposal: proposedSize)
    }

    private func calculateLayout(
        in proposedSize: ProposedViewSize,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> Lines {
        let items = subviews.enumerated().map {
            offset,
            subview in
            let size: ClosedRange<CGFloat>
            let subviewCache = cache.subviewsCache[offset]
            if subviewCache.ideal.breadth <= proposedSize.value(on: axis) {
                size = subviewCache.ideal.breadth ... subviewCache.max.breadth
            } else {
                size = subview.sizeThatFits(proposedSize).value(on: axis) ... subviewCache.max.breadth
            }
            let spacing = itemSpacing ?? (
                offset > cache.subviewsCache.startIndex
                ? cache.subviewsCache[offset - 1].spacing.distance(to: subviewCache.spacing, along: axis)
                : 0
            )
            return LineItem(
                subview: subview,
                cache: subviewCache,
                size: size,
                spacing: spacing
            )
        }

        let lineBreaker: any LineBreaking = if distributeItemsEvenly {
            KnuthPlassLineBreaker()
        } else {
            FlowLineBreaker()
        }

        let wrapped = lineBreaker.wrapItemsToLines(
            items: items,
            in: proposedSize.replacingUnspecifiedDimensions(by: .infinity).value(on: axis)
        )

        var lines: Lines = wrapped.map { line in
            let items = line.enumerated().map { offset, item in
                Line.Element(
                    item: (item.item.subview, item.item.cache),
                    size: item.item.subview
                        .sizeThatFits(ProposedViewSize(size: Size(breadth: item.size, depth: .infinity), axis: axis))
                        .size(on: axis),
                    leadingSpace: offset > 0 && line[offset - 1].item.cache.layoutValues.isLineBreak ? 0 : item.leadingSpace
                )
            }
            var size = items
                .map(\.size)
                .reduce(.zero, breadth: +, depth: max)
            size.breadth += items.sum(of: \.leadingSpace)
            return Lines.Element(
                item: items,
                size: size,
                leadingSpace: 0
            )
        }
        updateFlexibleItems(in: &lines, proposedSize: proposedSize)
        updateLineSpacings(in: &lines)
        updateAlignment(in: &lines)
        return lines
    }

    private func updateFlexibleItems(in lines: inout Lines, proposedSize: ProposedViewSize) {
        guard let justification else { return }
        for index in lines.indices {
            updateFlexibleItems(in: &lines[index], proposedSize: proposedSize, justification: justification)
        }
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

        guard remainingSpace > 0 else { return }

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

    private func updateLineSpacings(in lines: inout Lines) {
        if let lineSpacing {
            for index in lines.indices.dropFirst() {
                lines[index].leadingSpace = lineSpacing
            }
        } else {
            let lineSpacings = lines.map { line in
                line.item.reduce(into: ViewSpacing()) { $0.formUnion($1.item.cache.spacing) }
            }
            for (previous, index) in lines.indices.adjacentPairs() {
                let spacing = lineSpacings[index].distance(to: lineSpacings[previous], along: axis.perpendicular)
                lines[index].leadingSpace = spacing
            }
        }
    }

    private func updateAlignment(in lines: inout Lines) {
        let breadth = lines.map { $0.item.sum { $0.leadingSpace + $0.size.breadth } }.max() ?? 0
        for index in lines.indices where !lines[index].item.isEmpty {
            lines[index].item[0].leadingSpace += determineLeadingSpace(in: lines[index], breadth: breadth)
        }
    }

    private func determineLeadingSpace(in line: Lines.Element, breadth: CGFloat) -> CGFloat {
        guard let item = line.item.first(where: { $0.item.cache.ideal.breadth > 0 })?.item else { return 0 }
        let lineSize = line.item.sum { $0.leadingSpace + $0.size.breadth }
        let value = alignmentOnBreadth(item.subview.dimensions(.unspecified)) / item.cache.ideal.breadth
        let remainingSpace = breadth - lineSize
        return value * remainingSpace
    }
}

extension FlowLayout: Layout {
    @inlinable
    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        makeCache(subviews)
    }

    @inlinable
    static func vertical(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .top,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        self.init(
            axis: .vertical,
            itemSpacing: verticalSpacing,
            lineSpacing: horizontalSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly,
            alignmentOnBreadth: { $0[verticalAlignment] },
            alignmentOnDepth: { $0[horizontalAlignment] }
        )
    }

    @inlinable
    static func horizontal(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        self.init(
            axis: .horizontal,
            itemSpacing: horizontalSpacing,
            lineSpacing: verticalSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly,
            alignmentOnBreadth: { $0[horizontalAlignment] },
            alignmentOnDepth: { $0[verticalAlignment] }
        )
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
