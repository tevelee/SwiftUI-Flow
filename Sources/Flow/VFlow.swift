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
/// For large datasets where the eager per-item measurement of this view is
/// too expensive, see ``LazyVFlow``, which provides lazy rendering at the cost
/// of exact flow layout (items are placed in a uniform adaptive grid instead).
///
@frozen
public struct VFlow<Content: View>: View {
    @usableFromInline
    let layout: VFlowLayout
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
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        content = contentBuilder()
        layout = VFlowLayout(
            alignment: alignment,
            itemSpacing: itemSpacing,
            columnSpacing: columnSpacing,
            justified: justified,
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
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: spacing,
            columnSpacing: spacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            content: contentBuilder
        )
    }

    /// Creates a vertical flow with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - horizontalAlignment: The guide for aligning the subviews horizontally.
    ///   - verticalAlignment: The guide for aligning the subviews vertically.
    ///   - horizontalSpacing: The distance between subviews on the horizontal axis.
    ///   - verticalSpacing: The distance between subviews on the vertical axis.
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    @inlinable
    public init(
        horizontalAlignment: HorizontalAlignment,
        verticalAlignment: VerticalAlignment,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        content = contentBuilder()
        layout = VFlowLayout(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly
        )
    }

    @usableFromInline
    @Environment(\.flexibility) var flexibility
    @usableFromInline
    @Environment(\.maxLines) var _maxLinesCap
    @usableFromInline
    @Environment(\._flowItemSeparator) var _itemSeparator
    @usableFromInline
    @Environment(\._flowLineSeparator) var _lineSeparator
    @usableFromInline
    @Environment(\._flowOverflowBuilder) var _overflowBuilder
    @usableFromInline
    @Environment(\.flowSubviewOrdering) var _subviewOrdering

    @inlinable
    public var body: some View {
        if _itemSeparator != nil || _lineSeparator != nil {
            _FlowFeatureComposition(makeLayout: { AnyLayout(layout.withMaxLines($0).withSubviewOrdering(_subviewOrdering)) }, content: content)
        } else if let overflowBuilder = _overflowBuilder {
            _FlowWithOverflow(
                layout: AnyLayout(layout.withMaxLines(_maxLinesCap).withSubviewOrdering(_subviewOrdering)),
                content: content,
                overflowBuilder: overflowBuilder
            )
        } else {
            let effectiveLayout = (_maxLinesCap.map { layout.withMaxLines($0) } ?? layout)
                .withSubviewOrdering(_subviewOrdering)
            effectiveLayout {
                content
                    .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
                    .environment(\.maxLines, nil)
                    .environment(\.flowSubviewOrdering, .natural)
            }
        }
    }
}

extension VFlow: Animatable where Content == EmptyView {
    public typealias AnimatableData = EmptyAnimatableData
}

extension VFlow: Layout, Sendable where Content == EmptyView {
    /// Creates a vertical flow with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - columnSpacing: The distance between adjacent columns, or `nil` if you
    ///     want the flow to choose a default distance for each pair of columns.
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: itemSpacing,
            columnSpacing: columnSpacing,
            justified: justified,
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
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            alignment: alignment,
            spacing: spacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly
        ) {
            EmptyView()
        }
    }

    /// Creates a vertical flow with the given spacing and alignment.
    ///
    /// - Parameters:
    ///   - horizontalAlignment: The guide for aligning the subviews horizontally.
    ///   - verticalAlignment: The guide for aligning the subviews vertically.
    ///   - horizontalSpacing: The distance between subviews on the horizontal axis.
    ///   - verticalSpacing: The distance between subviews on the vertical axis.
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first columns, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each column, while respecting their order.
    @inlinable
    public init(
        horizontalAlignment: HorizontalAlignment,
        verticalAlignment: VerticalAlignment,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            justified: justified,
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
    nonisolated public func updateCache(_ cache: inout FlowLayoutCache, subviews: LayoutSubviews) {
        layout.layout.refreshCache(&cache, subviews: subviews)
    }

    @inlinable
    nonisolated public static var layoutProperties: LayoutProperties {
        VFlowLayout.layoutProperties
    }
}
