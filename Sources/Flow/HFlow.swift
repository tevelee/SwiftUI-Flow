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
/// For large datasets where the eager per-item measurement of this view is
/// too expensive, see ``LazyHFlow``, which provides lazy rendering at the cost
/// of exact flow layout (items are placed in a uniform adaptive grid instead).
///
public struct HFlow<Content: View>: View {
    let layout: HFlowLayout
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
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    public init(
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        content = contentBuilder()
        layout = HFlowLayout(
            alignment: alignment,
            itemSpacing: itemSpacing,
            rowSpacing: rowSpacing,
            justified: justified,
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
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: spacing,
            rowSpacing: spacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            content: contentBuilder
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
    ///   - contentBuilder: A view builder that creates the content of this flow.
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
        layout = HFlowLayout(
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly
        )
    }

    @Environment(\.flexibility) private var flexibility
    @Environment(\.flowComposers) private var flowComposers

    public var body: some View {
        let tagged = content.layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
        // The engine knows nothing about features: if any feature registered a composer (via its
        // modifier, in a feature target), hand off body construction to the composer chain; otherwise
        // lay the content out plainly. The composers fold their feature list back in via `makeLayout`.
        if flowComposers.isEmpty {
            layout { tagged }
        } else {
            composeFlowBody(
                composers: flowComposers,
                makeLayout: { features in AnyLayout(layout.withFeatures(features)) },
                content: AnyView(tagged)
            )
        }
    }
}

extension HFlow: Animatable where Content == EmptyView {
    public typealias AnimatableData = EmptyAnimatableData
}

extension HFlow: Layout, Sendable where Content == EmptyView {
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
    public init(
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: itemSpacing,
            rowSpacing: rowSpacing,
            justified: justified,
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
    ///   - justified: Whether the layout should fill the remaining
    ///     available space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Instead of prioritizing the first rows, this
    ///     mode tries to distribute items more evenly by minimizing the empty
    ///     spaces left in each row, while respecting their order.
    public init(
        alignment: VerticalAlignment = .center,
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

    nonisolated public func makeCache(subviews: LayoutSubviews) -> FlowLayoutCache {
        FlowLayoutCache(subviews, axis: .horizontal)
    }

    nonisolated public func updateCache(_ cache: inout FlowLayoutCache, subviews: LayoutSubviews) {
        layout.layout.refreshCache(&cache, subviews: subviews)
    }

    nonisolated public static var layoutProperties: LayoutProperties {
        HFlowLayout.layoutProperties
    }
}
