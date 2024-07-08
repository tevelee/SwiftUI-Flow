import SwiftUI

/// A view that arranges its children in a vertical flow layout.
///
/// The following example shows a simple vertical flow of 10 text views:
///
///     var body: some View {
///         VFlow(
///             alignment: .leading,
///             spacing: 10
///         ) {
///             ForEach(
///                 1...10,
///                 id: \.self
///             ) {
///                 Text("Item \($0)")
///             }
///         }
///     }
///
@frozen
public struct VFlow<Content: View>: View {
    @usableFromInline
    nonisolated let layout: VFlowLayout
    @usableFromInline
    let content: Content

    /// Creates a vertical flow with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - columnSpacing: The distance between adjacent columns, or `nil` if you
    ///     want the flow to choose a default distance for each pair of columns.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    ///   - content: A view builder that creates the content of this flow.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        content = contentBuilder()
        layout = VFlowLayout(
            alignment: alignment,
            itemSpacing: itemSpacing,
            columnSpacing: columnSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        )
    }

    /// Creates a vertical flow with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    ///   - content: A view builder that creates the content of this flow.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: spacing,
            columnSpacing: spacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly,
            content: contentBuilder
        )
    }

    public var body: some View {
        layout {
            content
        }
    }
}

extension VFlow: Animatable where Content == EmptyView {
    public typealias AnimatableData = EmptyAnimatableData
}

extension VFlow: Layout where Content == EmptyView {
    /// Creates a vertical flow with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - columnSpacing: The distance between adjacent columns, or `nil` if you
    ///     want the flow to choose a default distance for each pair of columns.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: itemSpacing,
            columnSpacing: columnSpacing,
            justification: justification,
            distributeItemsEvenly: distributeItemsEvenly
        ) {
            EmptyView()
        }
    }

    /// Creates a vertical flow with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
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
        FlowLayoutCache(subviews, axis: .vertical)
    }

    @inlinable
    nonisolated public static var layoutProperties: LayoutProperties {
        VFlowLayout.layoutProperties
    }
}
