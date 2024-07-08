import SwiftUI

/// A layout that arranges its children in a horizontally flowing manner.
@frozen
public struct HFlowLayout: Sendable {
    @usableFromInline
    nonisolated let layout: FlowLayout

    /// Creates a horizontal flow with the given spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each row by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    @inlinable
    public init(
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) {
        layout = .horizontal(
            alignment: alignment,
            itemSpacing: itemSpacing,
            lineSpacing: rowSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        )
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
    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .horizontal
        return properties
    }
}
