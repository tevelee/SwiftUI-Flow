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
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct VFlow<Content: View>: View {
    private let layout: VFlowLayout
    private let content: Content

    /// Creates an instance with the given spacing and horizontal alignment.
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
    ///   - content: A view builder that creates the content of this flow.
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justification: Justification? = nil,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        content = contentBuilder()
        layout = VFlowLayout(
            alignment: alignment,
            itemSpacing: itemSpacing,
            columnSpacing: columnSpacing,
            justification: justification
        )
    }

    /// Creates an instance with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    ///   - content: A view builder that creates the content of this flow.
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justification: Justification? = nil,
        @ViewBuilder content contentBuilder: () -> Content
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: spacing,
            columnSpacing: spacing,
            justification: justification,
            content: contentBuilder
        )
    }

    public var body: some View {
        layout {
            content
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension VFlow: Animatable where Content == EmptyView {
    public typealias AnimatableData = EmptyAnimatableData
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension VFlow: Layout where Content == EmptyView {
    /// Creates an instance with the given spacing and horizontal alignment.
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
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justification: Justification? = nil
    ) {
        self.init(
            alignment: alignment,
            itemSpacing: itemSpacing,
            columnSpacing: columnSpacing,
            justification: justification
        ) {
            EmptyView()
        }
    }

    /// Creates an instance with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - justification: Whether the layout should fill the remaining
    ///     available space in each column by stretching either items or spaces.
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justification: Justification? = nil
    ) {
        self.init(
            alignment: alignment,
            spacing: spacing,
            justification: justification
        ) {
            EmptyView()
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        layout.sizeThatFits(
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        layout.placeSubviews(
            in: bounds,
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }

    public static var layoutProperties: LayoutProperties {
        VFlowLayout.layoutProperties
    }
}
