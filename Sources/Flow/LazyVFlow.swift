import SwiftUI

/// A lazy-loading approximation of ``VFlow`` backed by `LazyHGrid`.
///
/// Unlike ``VFlow``, items are arranged in an adaptive grid where each row is
/// at least `minimumItemHeight` points tall. Items are not placed to exactly
/// fit their natural sizes — all rows share the same height calculated from
/// the available space — but rendering is lazy: SwiftUI only instantiates and
/// renders the items that are currently visible on screen.
///
/// Use this view instead of ``VFlow`` when your dataset is large enough that
/// the eager, per-item measurement performed by the `Layout`-protocol-based
/// ``VFlow`` becomes too expensive.
///
///     ScrollView(.horizontal) {
///         LazyVFlow(data: myItems, minimumItemHeight: 40, spacing: 8) { item in
///             Text(item.title)
///                 .padding(8)
///                 .background(Color.accentColor.opacity(0.2))
///                 .clipShape(RoundedRectangle(cornerRadius: 8))
///         }
///     }
///
/// - Note: Because this view relies on `LazyHGrid`, it requires a horizontal
///   `ScrollView` ancestor to actually defer rendering. Without one, all items
///   are rendered eagerly just like ``VFlow``.
public struct LazyVFlow<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    private let data: Data
    private let minimumItemHeight: CGFloat
    private let maximumItemHeight: CGFloat
    private let spacing: CGFloat
    private let content: (Data.Element) -> Content

    /// Creates a lazy vertical flow backed by `LazyHGrid`.
    ///
    /// - Parameters:
    ///   - data: The collection of identified data to display.
    ///   - minimumItemHeight: The minimum height for each grid cell. SwiftUI
    ///     fills the available vertical space with as many rows as possible
    ///     while respecting this minimum. Defaults to `40`.
    ///   - maximumItemHeight: The maximum height each grid cell may grow to.
    ///     Use this to cap how tall rows become when few items share a column.
    ///     Defaults to `.infinity` (uncapped).
    ///   - spacing: The distance between adjacent cells, both horizontally and
    ///     vertically. Defaults to `8`.
    ///   - content: A view builder that produces a view for each element.
    public init(
        data: Data,
        minimumItemHeight: CGFloat = 40,
        maximumItemHeight: CGFloat = .infinity,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.minimumItemHeight = minimumItemHeight
        self.maximumItemHeight = maximumItemHeight
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        LazyHGrid(
            rows: [GridItem(.adaptive(minimum: minimumItemHeight, maximum: maximumItemHeight), spacing: spacing)],
            spacing: spacing
        ) {
            ForEach(data) { item in
                content(item)
            }
        }
    }
}
