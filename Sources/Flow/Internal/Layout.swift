import CoreFoundation
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct FlowLayout {
    let axis: Axis
    var itemSpacing: CGFloat?
    var lineSpacing: CGFloat?
    var reversedBreadth: Bool = false
    var reversedDepth: Bool = false
    var justification: Justification?
    let align: (Dimensions) -> CGFloat

    private struct ItemWithSpacing<T> {
        var item: T
        var size: Size
        var spacing: CGFloat

        private init(
            _ item: T,
            size: Size,
            spacing: CGFloat = 0
        ) {
            self.item = item
            self.size = size
            self.spacing = spacing
        }

        init(_ item: Item, size: Size) where T == [ItemWithSpacing<Item>] {
            self.init([.init(item, size: size)], size: size)
        }

        mutating func append(_ item: Item, size: Size, spacing: CGFloat) where Self == ItemWithSpacing<Line> {
            self.item.append(.init(item, size: size, spacing: spacing))
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

        let lines = calculateLayout(in: proposedSize, of: subviews, cache: &cache)
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

        var bounds = bounds
        if reversedBreadth {
            bounds.reverseOrigin(along: axis)
        }
        if reversedDepth {
            bounds.reverseOrigin(along: axis.perpendicular)
        }
        var target = bounds.origin.size(on: axis)
        let originalBreadth = target.breadth
        let lines = calculateLayout(in: proposal, of: subviews, cache: &cache)
        for line in lines {
            if reversedDepth {
                target.depth -= line.size.depth
            }
            target.depth += line.spacing
            for item in line.item {
                if reversedBreadth {
                    target.breadth -= item.size.breadth
                }
                target.breadth += item.spacing
                alignAndPlace(item, in: line, at: target)
                if !reversedBreadth {
                    target.breadth += item.size.breadth
                }
            }
            if !reversedDepth {
                target.depth += line.size.depth
            }
            target.breadth = originalBreadth
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
        cache: inout FlowLayoutCache
    ) -> Lines {
        var lines: Lines = []
        let proposedBreadth = proposedSize.replacingUnspecifiedDimensions().value(on: axis)
        for (index, subview) in subviews.enumerated() {
            let size = subview.dimensions(.unspecified).size(on: axis)
            let cached = if cache.subviewsCache.indices.contains(index) {
                cache.subviewsCache[index]
            } else {
                FlowLayoutCache.SubviewCache(subview, axis: axis)
            }
            if let lastIndex = lines.indices.last {
                let spacing = self.itemSpacing(toPrevious: index, subviews: subviews)
                let additionalBreadth = spacing + size.breadth
                if lines[lastIndex].size.breadth + additionalBreadth <= proposedBreadth {
                    lines[lastIndex].append((subview, cached), size: size, spacing: spacing)
                    continue
                }
            }
            lines.append(.init((subview: subview, cache: cached), size: size))
        }
        // update flexible items in each line to stretch
        for index in lines.indices {
            updateFlexibleItems(in: &lines[index], proposedSize: proposedSize)
        }
        // adjust spacings on the perpendicular axis
        let lineSpacings = lines.map { line in
            line.item.reduce(into: ViewSpacing()) { $0.formUnion($1.item.cache.spacing) }
        }
        for index in lines.indices.dropFirst() {
            let spacing = self.lineSpacing ?? lineSpacings[index].distance(to: lineSpacings[index.advanced(by: -1)], along: axis.perpendicular)
            lines[index].spacing = spacing
        }
        return lines
    }

    private func itemSpacing<S: Subviews>(
        toPrevious index: S.Index,
        subviews: S
    ) -> CGFloat {
        guard index != subviews.startIndex else { return 0 }
        return self.itemSpacing ?? subviews[index.advanced(by: -1)].spacing.distance(to: subviews[index].spacing, along: axis)
    }

    private func updateFlexibleItems(in line: inout ItemWithSpacing<Line>, proposedSize: ProposedViewSize) {
        guard let justification else { return }
        let subviewsInPriorityOrder = line.item.enumerated().map { offset, subview in
            SubviewProperties(indexInLine: offset, spacing: subview.spacing, cache: subview.item.cache)
        }.sorted(using: [KeyPathComparator(\.cache.priority), KeyPathComparator(\.flexibility), KeyPathComparator(\.cache.ideal)])

        let sumOfIdeal = subviewsInPriorityOrder.map { $0.spacing + $0.cache.ideal }.reduce(into: 0, +=)
        var remainingSpace = proposedSize.value(on: axis) - sumOfIdeal
        let count = line.item.count

        if case .stretchSpaces = justification {
            let distributedSpace = remainingSpace / Double(count - 1)
            for index in line.item.indices.dropFirst() {
                line.item[index].spacing += distributedSpace
                remainingSpace -= distributedSpace
            }
        } else {
            let sumOfMax = subviewsInPriorityOrder.map { $0.spacing + $0.cache.max }.reduce(into: 0, +=)
            let potentialGrowth = sumOfMax - sumOfIdeal
            if potentialGrowth <= remainingSpace {
                for subview in subviewsInPriorityOrder {
                    line.item[subview.indexInLine].size.breadth = subview.cache.max
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
        justification: Justification? = nil
    ) -> FlowLayout {
        .init(
            axis: .vertical,
            itemSpacing: itemSpacing,
            lineSpacing: lineSpacing,
            justification: justification
        ) {
            $0[alignment]
        }
    }

    static func horizontal(
        alignment: VerticalAlignment,
        itemSpacing: CGFloat?,
        lineSpacing: CGFloat?,
        justification: Justification? = nil
    ) -> FlowLayout {
        .init(
            axis: .horizontal,
            itemSpacing: itemSpacing,
            lineSpacing: lineSpacing,
            justification: justification
        ) {
            $0[alignment]
        }
    }
}

private extension CGRect {
    mutating func reverseOrigin(along axis: Axis) {
        switch axis {
            case .horizontal:
                origin.x = maxX
            case .vertical:
                origin.y = maxY
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
    var flexibility: Double { cache.max - cache.ideal }
}
