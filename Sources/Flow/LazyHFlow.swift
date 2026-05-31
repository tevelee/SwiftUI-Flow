import SwiftUI

/// A lazy-loading approximation of ``HFlow`` backed by `LazyVGrid`.
///
/// Unlike ``HFlow``, items are arranged in an adaptive grid where each column
/// is at least `minimumItemWidth` points wide. Items are not placed to exactly
/// fit their natural sizes — all columns share the same width calculated from
/// the available space — but rendering is lazy: SwiftUI only instantiates and
/// renders the items that are currently visible on screen.
///
/// Use this view instead of ``HFlow`` when your dataset is large enough that
/// the eager, per-item measurement performed by the `Layout`-protocol-based
/// ``HFlow`` becomes too expensive.
///
///     ScrollView {
///         LazyHFlow(data: myItems, minimumItemWidth: 80, spacing: 8) { item in
///             Text(item.title)
///                 .padding(8)
///                 .background(Color.accentColor.opacity(0.2))
///                 .clipShape(RoundedRectangle(cornerRadius: 8))
///         }
///     }
///
/// - Note: Because this view relies on `LazyVGrid`, it requires a `ScrollView`
///   ancestor to actually defer rendering. Without one, all items are rendered
///   eagerly just like ``HFlow``.
public struct LazyHFlow<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    private let data: Data
    private let minimumItemWidth: CGFloat
    private let maximumItemWidth: CGFloat
    private let spacing: CGFloat
    private let content: (Data.Element) -> Content

    /// Creates a lazy horizontal flow backed by `LazyVGrid`.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - minimumItemWidth: The minimum width for each grid cell. SwiftUI
    ///     fills the available horizontal space with as many columns as
    ///     possible while respecting this minimum. Defaults to `80`.
    ///   - maximumItemWidth: The maximum width each grid cell may grow to.
    ///     Use this to cap how wide columns become when few items share a row.
    ///     Defaults to `.infinity` (uncapped).
    ///   - spacing: The distance between adjacent cells, both horizontally and
    ///     vertically. Defaults to `8`.
    ///   - content: A view builder that produces a view for each element.
    public init(
        data: Data,
        minimumItemWidth: CGFloat = 80,
        maximumItemWidth: CGFloat = .infinity,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.minimumItemWidth = minimumItemWidth
        self.maximumItemWidth = maximumItemWidth
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumItemWidth, maximum: maximumItemWidth), spacing: spacing)],
            spacing: spacing
        ) {
            ForEach(data) { item in
                content(item)
            }
        }
    }
}
