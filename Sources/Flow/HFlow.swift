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
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct HFlow<Content: View>: View {
    private let layout: HFlowLayout
    private let content: Content

    /// Creates a horizontal flow with the give spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - rowSpacing: The distance between rows of subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of rows.
    ///   - content: A view builder that creates the content of this flow.
    public init(alignment: VerticalAlignment = .center,
                itemSpacing: CGFloat? = nil,
                rowSpacing: CGFloat? = nil,
                @ViewBuilder content contentBuilder: () -> Content) {
        content = contentBuilder()
        layout = HFlowLayout(alignment: alignment,
                             itemSpacing: itemSpacing,
                             rowSpacing: rowSpacing)
    }

    /// Creates a horizontal flow with the give spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - content: A view builder that creates the content of this flow.
    public init(alignment: VerticalAlignment = .center,
                spacing: CGFloat? = nil,
                @ViewBuilder content contentBuilder: () -> Content) {
        self.init(alignment: alignment,
                  itemSpacing: spacing,
                  rowSpacing: spacing,
                  content: contentBuilder)
    }

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
    /// Creates a horizontal flow with the give spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - itemSpacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    ///   - rowSpacing: The distance between rows of subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of rows.
    public init(alignment: VerticalAlignment = .center,
                itemSpacing: CGFloat? = nil,
                rowSpacing: CGFloat? = nil) {
        self.init(alignment: alignment,
                  itemSpacing: itemSpacing,
                  rowSpacing: rowSpacing) {
            EmptyView()
        }
    }

    /// Creates a horizontal flow with the give spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of subviews.
    public init(alignment: VerticalAlignment = .center,
                spacing: CGFloat? = nil) {
        self.init(alignment: alignment,
                  spacing: spacing) {
            EmptyView()
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout.sizeThatFits(proposal: proposal,
                            subviews: subviews,
                            cache: &cache)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        layout.placeSubviews(in: bounds,
                             proposal: proposal,
                             subviews: subviews,
                             cache: &cache)
    }

    public static var layoutProperties: LayoutProperties {
        HFlowLayout.layoutProperties
    }
}
