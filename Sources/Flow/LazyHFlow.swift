import SwiftUI

/// A view that arranges its children in a horizontal flow layout, loading items
/// lazily as they become visible in a scroll view.
///
/// The layout is identical to ``HFlow``: each item is measured at its natural
/// size and rows break based on actual content widths. Items are loaded
/// incrementally as the user scrolls, making this suitable for large datasets.
///
/// When used without a `ScrollView` ancestor, all items are rendered eagerly,
/// matching the behaviour of ``HFlow``.
///
///     ScrollView {
///         LazyHFlow(data: myItems, spacing: 8) { item in
///             Text(item.title)
///                 .padding(8)
///                 .background(Color.accentColor.opacity(0.2))
///                 .clipShape(RoundedRectangle(cornerRadius: 8))
///         }
///     }
///
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
public struct LazyHFlow<LayoutContent: View>: View {
    let count: Int
    let layout: HFlowLayout
    let makeContent: (Int) -> LayoutContent

    @Environment(\.flexibility) var flexibility

    init(count: Int, layout: HFlowLayout, makeContent: @escaping (Int) -> LayoutContent) {
        self.count = count
        self.layout = layout
        self.makeContent = makeContent
    }

    // MARK: - Data-driven initialisers

    /// Creates a lazy horizontal flow with the given spacing and vertical alignment.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - alignment: The vertical alignment of items within each row.
    ///   - itemSpacing: The distance between adjacent items, or `nil` for the default.
    ///   - rowSpacing: The distance between rows, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across rows rather than
    ///     filling earlier rows first.
    ///   - content: A view builder that produces a view for each element.
    public init<Data: RandomAccessCollection, ElementContent: View>(
        data: Data,
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> ElementContent
    ) where Data.Element: Identifiable, LayoutContent == ForEach<[Data.Element], Data.Element.ID, ElementContent> {
        self.init(
            count: data.count,
            layout: HFlowLayout(
                alignment: alignment,
                itemSpacing: itemSpacing,
                rowSpacing: rowSpacing,
                justified: justified,
                distributeItemsEvenly: distributeItemsEvenly
            ),
            makeContent: { n in ForEach(Array(data.prefix(n)), content: content) }
        )
    }

    /// Creates a lazy horizontal flow with uniform spacing and a vertical alignment.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - alignment: The vertical alignment of items within each row.
    ///   - spacing: The distance between adjacent items and between rows, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across rows rather than
    ///     filling earlier rows first.
    ///   - content: A view builder that produces a view for each element.
    public init<Data: RandomAccessCollection, ElementContent: View>(
        data: Data,
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content: @escaping (Data.Element) -> ElementContent
    ) where Data.Element: Identifiable, LayoutContent == ForEach<[Data.Element], Data.Element.ID, ElementContent> {
        self.init(
            data: data,
            alignment: alignment,
            itemSpacing: spacing,
            rowSpacing: spacing,
            justified: justified,
            distributeItemsEvenly: distributeItemsEvenly,
            content: content
        )
    }

    /// Creates a lazy horizontal flow with independent axis alignment and spacing.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - horizontalAlignment: The guide for aligning items horizontally within each row.
    ///   - verticalAlignment: The guide for aligning items vertically within each row.
    ///   - horizontalSpacing: The distance between adjacent items on the horizontal axis.
    ///   - verticalSpacing: The distance between rows on the vertical axis.
    ///   - justified: Whether to fill the remaining space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across rows rather than
    ///     filling earlier rows first.
    ///   - content: A view builder that produces a view for each element.
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
            layout: HFlowLayout(
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

    /// Creates a lazy horizontal flow with free-form view-builder content.
    ///
    /// Content is rendered eagerly regardless of scroll position, matching the
    /// behaviour of ``HFlow``.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of items within each row.
    ///   - itemSpacing: The distance between adjacent items, or `nil` for the default.
    ///   - rowSpacing: The distance between rows, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across rows rather than
    ///     filling earlier rows first.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    public init(
        alignment: VerticalAlignment = .center,
        itemSpacing: CGFloat? = nil,
        rowSpacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> LayoutContent
    ) {
        let content = contentBuilder()
        self.init(
            count: 1,
            layout: HFlowLayout(
                alignment: alignment,
                itemSpacing: itemSpacing,
                rowSpacing: rowSpacing,
                justified: justified,
                distributeItemsEvenly: distributeItemsEvenly
            ),
            makeContent: { _ in content }
        )
    }

    /// Creates a lazy horizontal flow with uniform spacing and free-form view-builder content.
    ///
    /// Content is rendered eagerly regardless of scroll position, matching the
    /// behaviour of ``HFlow``.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of items within each row.
    ///   - spacing: The distance between adjacent items and between rows, or `nil` for the default.
    ///   - justified: Whether to fill the remaining space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across rows rather than
    ///     filling earlier rows first.
    ///   - contentBuilder: A view builder that creates the content of this flow.
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        justified: Bool = false,
        distributeItemsEvenly: Bool = false,
        @ViewBuilder content contentBuilder: () -> LayoutContent
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

    /// Creates a lazy horizontal flow with independent axis alignment and free-form view-builder content.
    ///
    /// Content is rendered eagerly regardless of scroll position, matching the
    /// behaviour of ``HFlow``.
    ///
    /// - Parameters:
    ///   - horizontalAlignment: The guide for aligning items horizontally within each row.
    ///   - verticalAlignment: The guide for aligning items vertically within each row.
    ///   - horizontalSpacing: The distance between adjacent items on the horizontal axis.
    ///   - verticalSpacing: The distance between rows on the vertical axis.
    ///   - justified: Whether to fill the remaining space in each row by stretching spaces.
    ///   - distributeItemsEvenly: Whether to minimise empty space across rows rather than
    ///     filling earlier rows first.
    ///   - contentBuilder: A view builder that creates the content of this flow.
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
            layout: HFlowLayout(
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
            geometryTransform: { LazyFlowGeometry(scrollMax: $0.bounds(of: .scrollView)?.maxY ?? .infinity, contentExtent: $0.size.height) },
            makeSizeModifier: LazyHFlowSizeModifier.init,
            makeContent: { [flexibility] n in
                layout {
                    makeContent(n)
                        .layoutValue(key: FlexibilityLayoutValueKey.self, value: flexibility)
                }
            }
        )
    }
}

private struct LazyHFlowSizeModifier: ViewModifier {
    let minHeight: CGFloat?
    func body(content: Content) -> some View {
        content.frame(minHeight: minHeight, alignment: .top)
    }
}
