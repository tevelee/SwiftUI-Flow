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
        /// Offset (from the leading depth edge) of the cross-axis alignment guide.
        /// For an item this is e.g. its text baseline; for a line it is the line's
        /// common guide (the max guide of its items, i.e. the ascent).
        var depthAlignmentGuide: CGFloat = 0
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
        var size =
            lines
            .map(\.size)
            .reduce(.zero, breadth: max, depth: +)
        size.depth += lines.sum(of: \.leadingSpace)
        // Justification needs a finite proposal to stretch to.
        if justified, proposedSize.value(on: axis).isFinite {
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
        bounds.origin = bounds.origin.finite(or: 0)
        var target = bounds.origin.size(on: axis)

        let lines = calculateLayout(in: proposal, of: subviews, cache: cache)

        for line in lines {
            adjust(&target, for: line, on: .vertical) { target in
                target.breadth = bounds.minimumValue(on: axis)

                for item in line.item {
                    adjust(&target, for: item, on: .horizontal) { target in
                        alignAndPlace(item, in: line, at: target)
                    }
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
        body: (inout Size) -> Void
    ) {
        target[axis] += item.leadingSpace
        body(&target)
        target[axis] += item.size[axis]
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
        // Align the item's guide (e.g. its baseline) onto the line's common guide.
        let offset = line.depthAlignmentGuide - item.depthAlignmentGuide
        // Skip a non-finite offset (e.g. unbounded item/line depth).
        if offset.isFinite {
            position.depth += offset
        }
        // Never hand a non-finite coordinate to CoreGraphics.
        let point = CGPoint(size: position, axis: axis).finite(or: 0)
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
            let spacing =
                itemSpacing
                ?? (offset > cache.subviewsCache.startIndex
                    ? cache.subviewsCache[offset - 1].spacing.distance(to: subviewCache.spacing, along: axis)
                    : 0)
            return .init(
                size: size,
                spacing: spacing,
                priority: subviewCache.priority,
                flexibility: subviewCache.layoutValues.flexibility,
                isLineBreakView: subviewCache.layoutValues.isLineBreak,
                shouldStartInNewLine: subviewCache.layoutValues.shouldStartInNewLine
            )
        }

        let lineBreaker: any LineBreaking =
            if distributeItemsEvenly {
                KnuthPlassLineBreaker()
            } else {
                FlowLineBreaker()
            }

        let wrapped = lineBreaker.wrapItemsToLines(
            items: items,
            in: proposedSize.replacingUnspecifiedDimensions(by: .infinity).value(on: axis)
        )

        var lines: Lines = wrapped.map { line in
            let items = line.map { item -> Line.Element in
                let subview = subviews[item.index]
                let proposal = ProposedViewSize(size: Size(breadth: item.size, depth: .infinity), axis: axis)
                let dimensions = subview.dimensions(proposal)
                return Line.Element(
                    item: (subview: subview, cache: cache.subviewsCache[item.index]),
                    size: dimensions.size(on: axis),
                    leadingSpace: item.leadingSpace,
                    depthAlignmentGuide: alignmentOnDepth(dimensions)
                )
            }
            // Depth is baseline-aware: enough room for the deepest guide (ascent)
            // plus the deepest extent below it (descent). For top/center/bottom
            // guides this reduces to the tallest item.
            let ascent = items.map(\.depthAlignmentGuide).max() ?? 0
            let descent = items.map { $0.size.depth - $0.depthAlignmentGuide }.max() ?? 0
            var size =
                items
                .map(\.size)
                .reduce(.zero, breadth: +, depth: max)
            size.depth = ascent + descent
            size.breadth += items.sum(of: \.leadingSpace)
            return Lines.Element(
                item: items,
                size: size,
                leadingSpace: 0,
                depthAlignmentGuide: ascent
            )
        }

        updateSpacesForJustifiedLayout(in: &lines, proposedSize: proposedSize)
        updateLineSpacings(in: &lines)
        updateAlignment(in: &lines)
        return lines
    }

    private func updateSpacesForJustifiedLayout(in lines: inout Lines, proposedSize: ProposedViewSize) {
        let availableSpace = proposedSize.value(on: axis)
        // Distributing leftover space is only meaningful when it's finite.
        guard justified, availableSpace.isFinite else { return }
        for (lineIndex, line) in lines.enumerated() {
            let items = line.item
            // Zero-size line-break markers get no share; justify across visible items.
            let visibleIndices = items.indices.filter { !items[$0].item.cache.layoutValues.isLineBreak }
            guard visibleIndices.count > 1 else { continue }
            let usedSpace = items.sum { $0.size[axis] + $0.leadingSpace }
            let distributedSpace = (availableSpace - usedSpace) / Double(visibleIndices.count - 1)
            for itemIndex in visibleIndices.dropFirst() {
                lines[lineIndex].item[itemIndex].leadingSpace += distributedSpace
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
        let leadingSpace = value * remainingSpace
        // Skip a non-finite offset (e.g. unbounded item breadth).
        return leadingSpace.isFinite ? leadingSpace : 0
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

extension CGFloat {
    /// The value if finite, else the fallback — keeps NaN/±∞ out of CoreGraphics.
    fileprivate func finite(or fallback: CGFloat) -> CGFloat {
        isFinite ? self : fallback
    }
}

extension CGPoint {
    fileprivate func finite(or fallback: CGFloat) -> CGPoint {
        CGPoint(x: x.finite(or: fallback), y: y.finite(or: fallback))
    }
}
