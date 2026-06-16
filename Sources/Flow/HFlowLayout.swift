import SwiftUI

/// A layout that arranges its children in a horizontally flowing manner.
@frozen
public struct HFlowLayout: Sendable {
    @usableFromInline
    let layout: FlowLayout

    /// Creates a horizontal flow with the given spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - rowSpacing: The distance between rows of subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of rows.
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    @inlinable
    public init(
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            horizontalAlignment: .leading,
            verticalAlignment: alignment,
            horizontalSpacing: itemSpacing,
            verticalSpacing: rowSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly
        )
    }

    /// Creates a horizontal flow with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - horizontalAlignment: The guide for aligning the subviews horizontally.
    ///   - verticalAlignment: The guide for aligning the subviews vertically.
    ///   - horizontalSpacing: The distance between subviews on the horizontal axis.
    ///   - verticalSpacing: The distance between subviews on the vertical axis.
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    @inlinable
    public init(
        horizontalAlignment: HorizontalAlignment,
        verticalAlignment: VerticalAlignment,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) {
        layout = .horizontal(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly
        )
    }
}

extension HFlowLayout {
    @usableFromInline
    init(layout: FlowLayout) {
        self.layout = layout
    }

    /// Returns a copy of this layout capped to `maxLines` rows.
    /// Items beyond the limit are hidden; pass `nil` to remove any cap.
    @inlinable
    public func withMaxLines(_ maxLines: Int?) -> HFlowLayout {
        HFlowLayout(layout: layout.withMaxLines(maxLines))
    }

    /// Returns a copy of this layout using the given subview ordering strategy.
    @inlinable
    public func withSubviewOrdering(_ ordering: FlowSubviewOrdering) -> HFlowLayout {
        HFlowLayout(layout: layout.withSubviewOrdering(ordering))
    }
}

extension HFlowLayout: Layout {
    @inlinable
    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) -> CGSize {
        layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    @inlinable
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout FlowLayoutCache) {
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    @inlinable
    public func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: .horizontal)
    }

    @inlinable
    public func updateCache(_ cache: inout FlowLayoutCache, subviews: LayoutSubviews) {
        layout.refreshCache(&cache, subviews: subviews)
    }

    @inlinable
    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .horizontal
        return properties
    }
}
