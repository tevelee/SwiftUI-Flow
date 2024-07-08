import SwiftUI

/// A view that arranges its children in a horizontal flow layout.
///
/// The following example shows a simple horizontal flow of five text views:
///
///     var body: some View {
///         HFlow(
///             alignment: .top,
///             spacing: 10
///         ) {
///             ForEach(
///                 1...5,
///                 id: \.self
///             ) {
///                 Text("Item \($0)")
///             }
///         }
///     }
///
@frozen
public struct HFlow<Content: View>: View {
    @usableFromInline 
    nonisolated let layout: HFlowLayout
    @usableFromInline
    let content: Content

    /// Creates a horizontal flow with the given spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - rowSpacing: The distance between rows of subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of rows.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each row by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    ///   - content: A view builder that creates the content of this flow.
    @inlinable 
    public init(
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        content = contentBuilder()
        layout = HFlowLayout(
            alignment: alignment,
            itemSpacing: itemSpacing,
            rowSpacing: rowSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        )
    }

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
    ///   - content: A view builder that creates the content of this flow.
    @inlinable 
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: spacing,
            rowSpacing: spacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly,
            content: contentBuilder
        )
    }

    @inlinable 
    public var body: some View {
        layout {
            content
        }
    }
}

extension HFlow: Animatable where Content == EmptyView {
    public typealias AnimatableData = EmptyAnimatableData
}

extension HFlow: Layout where Content == EmptyView {
    /// Creates a horizontal flow with the given spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - rowSpacing: The distance between rows of subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of rows.
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
        self.init(
            alignment: alignment,
            itemSpacing: itemSpacing,
            rowSpacing: rowSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        ) {
            EmptyView()
        }
    }

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
        spacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            alignment: alignment,
            spacing: spacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        ) {
            EmptyView()
        }
    }

    @inlinable 
    nonisolated public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout FlowLayoutCache
    ) -> CGSize {
        layout.sizeThatFits(
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }

    @inlinable 
    nonisolated public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout FlowLayoutCache
    ) {
        layout.placeSubviews(
            in: bounds,
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }

    @inlinable
    nonisolated public func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: .horizontal)
    }

    @inlinable 
    nonisolated public static var layoutProperties: LayoutProperties {
        HFlowLayout.layoutProperties
    }
}
