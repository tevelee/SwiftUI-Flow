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

    // MARK: - Layout protocol entry points

    @usableFromInline
    func sizeThatFits(
        proposal proposedSize: ProposedViewSize,
        subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let lines = calculateLayout(in: proposedSize, of: subviews, cache: &cache)
        var size = lines.reduce(Size.zero) { acc, line in
            Size(breadth: max(acc.breadth, line.size.breadth), depth: acc.depth + line.size.depth + line.leadingSpace)
        }
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
        let lines = calculateLayout(in: effectiveProposal(for: proposal, in: bounds), of: subviews, cache: &cache)

        for line in lines {
            adjustDepth(&target, for: line) { target in
                target.breadth = bounds.minimumValue(on: axis)

                for item in line.item {
                    adjustBreadth(&target, for: item) { target in
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

    // MARK: - Placement helpers

    private func adjustDepth<T>(_ target: inout Size, for item: ItemWithSpacing<T>, body: (inout Size) -> Void) {
        target.depth += item.leadingSpace
        body(&target)
        target.depth += item.size.depth
    }

    private func adjustBreadth<T>(_ target: inout Size, for item: ItemWithSpacing<T>, body: (inout Size) -> Void) {
        target.breadth += item.leadingSpace
        body(&target)
        target.breadth += item.size.breadth
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

    private func effectiveProposal(for proposal: ProposedViewSize, in bounds: CGRect) -> ProposedViewSize {
        // .frame(maxHeight:) passes the parent's nil proposal through unchanged but clips
        // our reported size to maxHeight, so use bounds when the proposal is unbounded.
        guard !proposal.value(on: axis).isFinite else {
            return proposal
        }
        return ProposedViewSize(
            size: Size(
                breadth: bounds.size.value(on: axis),
                depth: proposal.value(on: axis.perpendicular)
            ),
            axis: axis
        )
    }

    // MARK: - Layout pipeline

    private func calculateLayout(
        in proposedSize: ProposedViewSize,
        of subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> Lines {
        let wrapped = wrappedLines(in: proposedSize, of: subviews, cache: &cache)
        var lines = makeLines(from: wrapped, of: subviews, cache: cache)

        updateSpacesForJustifiedLayout(in: &lines, proposedSize: proposedSize)
        updateLineSpacings(in: &lines)
        updateAlignment(in: &lines)
        return lines
    }

    private func wrappedLines(
        in proposedSize: ProposedViewSize,
        of subviews: some Subviews,
        cache: inout FlowLayoutCache
    ) -> LineBreakingOutput {
        let key = FlowLayoutCache.LineBreakingKey(proposedSize: proposedSize, axis: axis)
        if let cached = cache.cachedLineBreaking(for: key) {
            return cached
        }

        let wrapped = makeLineBreaker().wrapItemsToLines(
            items: makeLineBreakingInput(in: proposedSize, of: subviews, cache: cache),
            in: availableLineBreakingSpace(in: proposedSize)
        )
        cache.cacheLineBreaking(wrapped, for: key)
        return wrapped
    }

    private func makeLineBreaker() -> any LineBreaking {
        distributeItemsEvenly ? KnuthPlassLineBreaker() : FlowLineBreaker()
    }

    private func makeLineBreakingInput(
        in proposedSize: ProposedViewSize,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> LineBreakingInput {
        subviews.enumerated().map { offset, subview in
            lineBreakingItem(
                for: subview,
                at: offset,
                in: proposedSize,
                cache: cache
            )
        }
    }

    private func lineBreakingItem(
        for subview: some Subview,
        at offset: Int,
        in proposedSize: ProposedViewSize,
        cache: FlowLayoutCache
    ) -> LineItemInput {
        let subviewCache = cache.subviewsCache[offset]
        let minimumBreadth = minimumBreadth(for: subview, cache: subviewCache, in: proposedSize)
        let maximumBreadth = subviewCache.max.breadth
        return LineItemInput(
            size: min(minimumBreadth, maximumBreadth) ... max(minimumBreadth, maximumBreadth),
            spacing: spacing(before: offset, cache: cache),
            priority: subviewCache.priority,
            flexibility: subviewCache.layoutValues.flexibility,
            isLineBreakView: subviewCache.layoutValues.isLineBreak,
            shouldStartInNewLine: subviewCache.layoutValues.shouldStartInNewLine
        )
    }

    private func minimumBreadth(
        for subview: some Subview,
        cache subviewCache: FlowLayoutCache.SubviewCache,
        in proposedSize: ProposedViewSize
    ) -> CGFloat {
        if subviewCache.ideal.breadth <= proposedSize.value(on: axis) {
            return subviewCache.ideal.breadth
        }
        return subview.sizeThatFits(proposedSize).value(on: axis)
    }

    private func spacing(before offset: Int, cache: FlowLayoutCache) -> CGFloat {
        if let itemSpacing {
            return itemSpacing
        }
        guard offset > cache.subviewsCache.startIndex else {
            return 0
        }
        let previous = cache.subviewsCache[offset - 1].spacing
        let current = cache.subviewsCache[offset].spacing
        return previous.distance(to: current, along: axis)
    }

    private func availableLineBreakingSpace(in proposedSize: ProposedViewSize) -> CGFloat {
        proposedSize.replacingUnspecifiedDimensions(by: .infinity).value(on: axis)
    }

    // MARK: - Line construction

    private func makeLines(
        from wrapped: LineBreakingOutput,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> Lines {
        wrapped.map { makeLine(from: $0, of: subviews, cache: cache) }
    }

    private func makeLine(
        from wrappedLine: LineOutput,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> Lines.Element {
        let naturalDepth = wrappedLine.map { cache.subviewsCache[$0.index].ideal.depth }.max() ?? 0
        let items = wrappedLine.map {
            makeLineItem(from: $0, naturalDepth: naturalDepth, of: subviews, cache: cache)
        }
        let metrics = lineMetrics(for: items)
        return Lines.Element(
            item: items,
            size: metrics.size,
            leadingSpace: 0,
            depthAlignmentGuide: metrics.depthAlignmentGuide
        )
    }

    private func makeLineItem(
        from wrappedItem: LineItemOutput,
        naturalDepth: CGFloat,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> Line.Element {
        let subview = subviews[wrappedItem.index]
        let subviewCache = cache.subviewsCache[wrappedItem.index]
        let proposal = ProposedViewSize(
            size: Size(
                breadth: wrappedItem.size,
                depth: proposedDepth(for: subviewCache, naturalDepth: naturalDepth)
            ),
            axis: axis
        )
        let dimensions = subview.dimensions(proposal)
        return Line.Element(
            item: (subview: subview, cache: subviewCache),
            size: dimensions.size(on: axis),
            leadingSpace: wrappedItem.leadingSpace,
            depthAlignmentGuide: alignmentOnDepth(dimensions)
        )
    }

    private func proposedDepth(
        for subviewCache: FlowLayoutCache.SubviewCache,
        naturalDepth: CGFloat
    ) -> CGFloat {
        let canExpandDepth = subviewCache.max.depth.isInfinite && subviewCache.ideal.depth.isFinite
        return canExpandDepth ? naturalDepth : .infinity
    }

    private func lineMetrics(for items: Line) -> (size: Size, depthAlignmentGuide: CGFloat) {
        // Depth is baseline-aware: enough room for the deepest guide (ascent)
        // plus the deepest extent below it (descent). For top/center/bottom
        // guides this reduces to the tallest item.
        let ascent = items.map(\.depthAlignmentGuide).max() ?? 0
        let descent = items.map { $0.size.depth - $0.depthAlignmentGuide }.max() ?? 0
        let breadth = items.sum { $0.size.breadth + $0.leadingSpace }
        return (size: Size(breadth: breadth, depth: ascent + descent), depthAlignmentGuide: ascent)
    }

    // MARK: - Post-processing

    private func updateSpacesForJustifiedLayout(in lines: inout Lines, proposedSize: ProposedViewSize) {
        let availableSpace = proposedSize.value(on: axis)
        // Distributing leftover space is only meaningful when it's finite.
        guard justified, availableSpace.isFinite else { return }
        for (lineIndex, line) in lines.enumerated() {
            let items = line.item
            // Zero-size line-break markers get no share; justify across visible items.
            let visibleIndices = items.indices.filter { !items[$0].item.cache.layoutValues.isLineBreak }
            guard visibleIndices.count > 1 else { continue }
            let usedSpace = items.sum { $0.size.breadth + $0.leadingSpace }
            let distributedSpace = (availableSpace - usedSpace) / Double(visibleIndices.count - 1)
            for itemIndex in visibleIndices.dropFirst() {
                lines[lineIndex].item[itemIndex].leadingSpace += distributedSpace
            }
        }
    }

    private func updateLineSpacings(in lines: inout Lines) {
        if let lineSpacing {
            for index in lines.indices.dropFirst() where !isLineBreakLine(lines[index]) {
                lines[index].leadingSpace = lineSpacing
            }
        } else {
            let lineSpacings = lines.map { line in
                line.item.reduce(into: ViewSpacing()) { $0.formUnion($1.item.cache.spacing) }
            }
            for (previous, index) in lines.indices.adjacentPairs() where !isLineBreakLine(lines[index]) {
                let spacing = lineSpacings[index].distance(to: lineSpacings[previous], along: axis.perpendicular)
                lines[index].leadingSpace = spacing
            }
        }
    }

    private func isLineBreakLine(_ line: Lines.Element) -> Bool {
        line.item.count == 1 && line.item[0].item.cache.layoutValues.isLineBreak
    }

    private func updateAlignment(in lines: inout Lines) {
        let lineBreadths = lines.map { $0.item.sum { $0.leadingSpace + $0.size.breadth } }
        let breadth = lineBreadths.max() ?? 0
        for index in lines.indices where !lines[index].item.isEmpty {
            lines[index].item[0].leadingSpace += determineLeadingSpace(in: lines[index], lineSize: lineBreadths[index], breadth: breadth)
        }
    }

    private func determineLeadingSpace(in line: Lines.Element, lineSize: CGFloat, breadth: CGFloat) -> CGFloat {
        guard let item = line.item.first(where: { $0.item.cache.ideal.breadth > 0 })?.item else { return 0 }
        let value = alignmentOnBreadth(item.subview.dimensions(.unspecified)) / item.cache.ideal.breadth
        let remainingSpace = breadth - lineSize
        let leadingSpace = value * remainingSpace
        // Skip a non-finite offset (e.g. unbounded item breadth).
        return leadingSpace.isFinite ? leadingSpace : 0
    }
}

// MARK: - Factory

extension FlowLayout {
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

// MARK: - Layout protocol

extension FlowLayout: Layout {
    @inlinable
    func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        makeCache(subviews)
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
