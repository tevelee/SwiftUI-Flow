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
    let justified: Bool
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
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        alignmentOnBreadth: @escaping @Sendable (any Dimensions) -> CGFloat,
        alignmentOnDepth: @escaping @Sendable (any Dimensions) -> CGFloat
    ) {
        self.axis = axis
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.justified = justified
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
        if justified {
            size.breadth = proposedSize.value(on: axis)
        }
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

        var bounds = bounds
        bounds.origin.replaceNaN(with: 0)
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
            if position.depth.isNaN {
                position.depth = .infinity
            }
        }
        let point = CGPoint(size: position, axis: axis)
        item.item.subview.place(at: point, anchor: .topLeading, proposal: proposedSize)
    }

    private func calculateLayout(
        in proposedSize: ProposedViewSize,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> Lines {
        let items: LineBreakingInput = subviews.enumerated().map { offset, subview in
            let minValue: CGFloat
            let subviewCache = cache.subviewsCache[offset]
            if subviewCache.ideal.breadth <= proposedSize.value(on: axis) {
                minValue = subviewCache.ideal.breadth
            } else {
                minValue = subview.sizeThatFits(proposedSize).value(on: axis)
            }
            let maxValue = subviewCache.max.breadth
            let size = min(minValue, maxValue) ... max(minValue, maxValue)
            let spacing = itemSpacing ?? (
                offset > cache.subviewsCache.startIndex
                ? cache.subviewsCache[offset - 1].spacing.distance(to: subviewCache.spacing, along: axis)
                : 0
            )
            return .init(
                size: size,
                spacing: spacing,
                priority: subviewCache.priority,
                flexibility: subviewCache.layoutValues.flexibility,
                isLineBreakView: subviewCache.layoutValues.isLineBreak,
                shouldStartInNewLine: subviewCache.layoutValues.shouldStartInNewLine
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
            let items = line.map { item in
                Line.Element(
                    item: (subview: subviews[item.index], cache: cache.subviewsCache[item.index]),
                    size: subviews[item.index]
                        .sizeThatFits(ProposedViewSize(size: Size(breadth: item.size, depth: .infinity), axis: axis))
                        .size(on: axis),
                    leadingSpace: item.leadingSpace
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

        // TODO: account for manual line breaks

        updateSpacesForJustifiedLayout(in: &lines, proposedSize: proposedSize)
        updateLineSpacings(in: &lines)
        updateAlignment(in: &lines)
        return lines
    }

    private func updateSpacesForJustifiedLayout(in lines: inout Lines, proposedSize: ProposedViewSize) {
        guard justified else { return }
        for (lineIndex, line) in lines.enumerated() {
            let items = line.item
            let remainingSpace = proposedSize.value(on: axis) - items.sum { $0.size[axis] + $0.leadingSpace }
            for (itemIndex, item) in items.enumerated().dropFirst() {
                let distributedSpace = remainingSpace / Double(items.count - 1)
                lines[lineIndex].item[itemIndex].leadingSpace = item.leadingSpace + distributedSpace
            }
        }
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
        // remove space from empty lines (where the only item is a line break view)
        for index in lines.indices where lines[index].item.count == 1 && lines[index].item[0].item.cache.layoutValues.isLineBreak {
            lines[index].leadingSpace = 0
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
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        self.init(
            axis: .vertical,
            itemSpacing: verticalSpacing,
            lineSpacing: horizontalSpacing,
            justified: justified,
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
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) -> FlowLayout {
        self.init(
            axis: .horizontal,
            itemSpacing: horizontalSpacing,
            lineSpacing: verticalSpacing,
            justified: justified,
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

private extension CGPoint {
    mutating func replaceNaN(with value: CGFloat) {
        x.replaceNaN(with: value)
        y.replaceNaN(with: value)
    }
}

private extension CGFloat {
    mutating func replaceNaN(with value: CGFloat) {
        if isNaN {
            self = value
        }
    }
}
