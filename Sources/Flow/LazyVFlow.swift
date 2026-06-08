import SwiftUI

/// A view that arranges its children in a vertical flow layout, loading items
/// lazily as they become visible in a horizontal scroll view.
///
/// The layout is identical to ``VFlow``: each item is measured at its natural
/// size and columns break based on actual content heights. Items are loaded
/// incrementally as the user scrolls, making this suitable for large datasets.
///
/// When used without a `ScrollView` ancestor, all items are rendered eagerly,
/// matching the behaviour of ``VFlow``.
///
///     ScrollView(.horizontal) {
///         LazyVFlow(data: myItems, spacing: 8) { item in
///             Text(item.title)
///                 .padding(8)
///                 .background(Color.accentColor.opacity(0.2))
///                 .clipShape(RoundedRectangle(cornerRadius: 8))
///         }
///     }
///
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@frozen
public struct LazyVFlow<LayoutContent: View>: View {
    @usableFromInline
    let count: Int
    @usableFromInline
    let layout: VFlowLayout
    @usableFromInline
    let makeContent: (Int) -> LayoutContent

    @usableFromInline
    @Environment(\.flexibility) var flexibility

    @usableFromInline
    init(count: Int, layout: VFlowLayout, makeContent: @escaping (Int) -> LayoutContent) {
        self.count = count
        self.layout = layout
        self.makeContent = makeContent
    }

    // MARK: - Data-driven initialisers

    /// Creates a lazy vertical flow with the given spacing and horizontal alignment.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - alignment: The horizontal alignment of items within each column.
    ///   - itemSpacing: The distance between adjacent items, or `nil` for the default.
    ///   - columnSpacing: The distance between columns, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across columns rather than
    ///     filling earlier columns first.
    ///   - content: A view builder that produces a view for each element.
    @inlinable
    public init<Data: RandomAccessCollection, ElementContent: View>(
        data: Data,
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> ElementContent
    ) where Data.Element: Identifiable, LayoutContent == ForEach<[Data.Element], Data.Element.ID, ElementContent> {
        self.init(
            count: data.count,
            layout: VFlowLayout(
                alignment: alignment,
                itemSpacing: itemSpacing,
                columnSpacing: columnSpacing,
                justified: justified,
                distributeItemsEvenly: distributeItemsEvenly
            ),
            makeContent: { n in ForEach(Array(data.prefix(n)), content: content) }
        )
    }

    /// Creates a lazy vertical flow with uniform spacing and a horizontal alignment.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - alignment: The horizontal alignment of items within each column.
    ///   - spacing: The distance between adjacent items and between columns, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across columns rather than
    ///     filling earlier columns first.
    ///   - content: A view builder that produces a view for each element.
    @inlinable
    public init<Data: RandomAccessCollection, ElementContent: View>(
        data: Data,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> ElementContent
    ) where Data.Element: Identifiable, LayoutContent == ForEach<[Data.Element], Data.Element.ID, ElementContent> {
        self.init(
            data: data,
            alignment: alignment,
            itemSpacing: spacing,
            columnSpacing: spacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            content: content
        )
    }

    /// Creates a lazy vertical flow with independent axis alignment and spacing.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - horizontalAlignment: The guide for aligning items horizontally within each column.
    ///   - verticalAlignment: The guide for aligning items vertically within each column.
    ///   - horizontalSpacing: The distance between adjacent items on the horizontal axis.
    ///   - verticalSpacing: The distance between columns on the vertical axis.
    ///   - justified: Whether to fill the remaining space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across columns rather than
    ///     filling earlier columns first.
    ///   - content: A view builder that produces a view for each element.
    @inlinable
    public init<Data: RandomAccessCollection, ElementContent: View>(
        data: Data,
        horizontalAlignment: HorizontalAlignment,
        verticalAlignment: VerticalAlignment,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> ElementContent
    ) where Data.Element: Identifiable, LayoutContent == ForEach<[Data.Element], Data.Element.ID, ElementContent> {
        self.init(
            count: data.count,
            layout: VFlowLayout(
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                justified: justified,
                distributeItemsEvenly: distributeItemsEvenly
            ),
            makeContent: { n in ForEach(Array(data.prefix(n)), content: content) }
        )
    }

    // MARK: - ViewBuilder initialisers

    /// Creates a lazy vertical flow with free-form view-builder content.
    ///
    /// Content is rendered eagerly regardless of scroll position, matching the
    /// behaviour of ``VFlow``.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of items within each column.
    ///   - itemSpacing: The distance between adjacent items, or `nil` for the default.
    ///   - columnSpacing: The distance between columns, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across columns rather than
    ///     filling earlier columns first.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> LayoutContent
    ) {
        let content = contentBuilder()
        self.init(
            count: 1,
            layout: VFlowLayout(
                alignment: alignment,
                itemSpacing: itemSpacing,
                columnSpacing: columnSpacing,
                justified: justified,
                distributeItemsEvenly: distributeItemsEvenly
            ),
            makeContent: { _ in content }
        )
    }

    /// Creates a lazy vertical flow with uniform spacing and free-form view-builder content.
    ///
    /// Content is rendered eagerly regardless of scroll position, matching the
    /// behaviour of ``VFlow``.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of items within each column.
    ///   - spacing: The distance between adjacent items and between columns, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across columns rather than
    ///     filling earlier columns first.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    @inlinable
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> LayoutContent
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

    /// Creates a lazy vertical flow with independent axis alignment and free-form view-builder content.
    ///
    /// Content is rendered eagerly regardless of scroll position, matching the
    /// behaviour of ``VFlow``.
    ///
    /// - Parameters:
    ///   - horizontalAlignment: The guide for aligning items horizontally within each column.
    ///   - verticalAlignment: The guide for aligning items vertically within each column.
    ///   - horizontalSpacing: The distance between adjacent items on the horizontal axis.
    ///   - verticalSpacing: The distance between columns on the vertical axis.
    ///   - justified: Whether to fill the remaining space in each column by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across columns rather than
    ///     filling earlier columns first.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    @inlinable
    public init(
        horizontalAlignment: HorizontalAlignment,
        verticalAlignment: VerticalAlignment,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> LayoutContent
    ) {
        let content = contentBuilder()
        self.init(
            count: 1,
            layout: VFlowLayout(
                horizontalAlignment: horizontalAlignment,
                verticalAlignment: verticalAlignment,
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                justified: justified,
                distributeItemsEvenly: distributeItemsEvenly
            ),
            makeContent: { _ in content }
        )
    }

    // MARK: - Body

    public var body: some View {
        let flexibility = flexibility
        LazyFlowBody(
            count: count,
            geometryTransform: { LazyFlowGeometry(scrollMax: $0.bounds(of: .scrollView)?.maxX ?? .infinity, contentExtent: $0.size.width) },
            makeSizeModifier: LazyVFlowSizeModifier.init,
            makeContent: { [flexibility] n in
                layout {
                    makeContent(n)
                        .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
                }
            }
        )
    }
}

private struct LazyVFlowSizeModifier: ViewModifier {
    let minWidth: CGFloat?
    func body(content: Content) -> some View {
        content.frame(minWidth: minWidth, alignment: .leading)
    }
}
