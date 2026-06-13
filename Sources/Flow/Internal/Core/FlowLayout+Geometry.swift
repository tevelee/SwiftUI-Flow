import CoreFoundation
import SwiftUI

// Pipeline phase — geometry.
//
// Turns the wrapped lines (line-breaker output, in subview-index space) into measured geometry: every
// item placed at its proposed size, every line's metrics derived from its items. The two value types
// here, ``PlacedItem`` and ``LayoutLine``, are what the remaining phases (space distribution, then
// placement) operate on.

/// One item placed on a line. `depthGuide` is the item's own cross-axis alignment guide — e.g. its
/// text baseline — measured from the line's leading depth edge.
struct PlacedItem {
    var subview: any Subview
    var cache: FlowLayoutCache.SubviewCache
    var size: Size
    var leadingSpace: CGFloat
    var depthGuide: CGFloat
}

/// One line in the laid-out result. `depthGuide` is the line's common guide — the max of its items'
/// guides, i.e. the ascent — onto which each item's own guide is aligned.
struct LayoutLine {
    var items: [PlacedItem]
    var size: Size
    var leadingSpace: CGFloat
    var depthGuide: CGFloat
}

/// A block the placement walk advances over: it contributes its `leadingSpace` before, then its
/// `size` after. Both an item (along breadth) and a line (along depth) are placed this way.
protocol Spaced {
    var leadingSpace: CGFloat { get }
    var size: Size { get }
}

extension PlacedItem: Spaced {}
extension LayoutLine: Spaced {}

extension FlowLayout {
    /// Turns the wrapped lines (breaker output, subview-index space) into placed geometry: each item
    /// measured at its proposed size, each line's metrics computed from its items.
    func buildGeometry(
        of wrapped: WrappedLines,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> [LayoutLine] {
        wrapped.map { layoutLine(from: $0, of: subviews, cache: cache) }
    }

    private func layoutLine(
        from wrappedLine: WrappedLine,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> LayoutLine {
        let naturalDepth = wrappedLine.map { cache.subviewsCache[$0.index].ideal.depth }.max() ?? 0
        let items = wrappedLine.map {
            placedItem(from: $0, naturalDepth: naturalDepth, of: subviews, cache: cache)
        }
        let metrics = lineMetrics(for: items)
        return LayoutLine(items: items, size: metrics.size, leadingSpace: 0, depthGuide: metrics.depthGuide)
    }

    private func placedItem(
        from wrappedItem: WrappedItem,
        naturalDepth: CGFloat,
        of subviews: some Subviews,
        cache: FlowLayoutCache
    ) -> PlacedItem {
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
        return PlacedItem(
            subview: subview,
            cache: subviewCache,
            size: dimensions.size(on: axis),
            leadingSpace: wrappedItem.leadingSpace,
            depthGuide: alignmentOnDepth(dimensions)
        )
    }

    private func proposedDepth(
        for subviewCache: FlowLayoutCache.SubviewCache,
        naturalDepth: CGFloat
    ) -> CGFloat {
        // Propose the line's natural depth to views that can expand (max=∞, ideal finite),
        // so they fill the line. Propose .infinity to everything else so they report their
        // natural size (identical to an unspecified proposal for non-expandable views).
        let canExpandDepth = subviewCache.max.depth.isInfinite && subviewCache.ideal.depth.isFinite
        return canExpandDepth ? naturalDepth : .infinity
    }

    private func lineMetrics(for items: [PlacedItem]) -> (size: Size, depthGuide: CGFloat) {
        // Depth is baseline-aware: enough room for the deepest guide (ascent)
        // plus the deepest extent below it (descent). For top/center/bottom
        // guides this reduces to the tallest item.
        let ascent = items.map(\.depthGuide).max() ?? 0
        let descent = items.map { $0.size.depth - $0.depthGuide }.max() ?? 0
        let breadth = items.sum { $0.size.breadth + $0.leadingSpace }
        return (size: Size(breadth: breadth, depth: ascent + descent), depthGuide: ascent)
    }
}
