import SwiftUI

struct LazyFlowGeometry: Equatable, Sendable {
    var scrollMax: CGFloat
    var contentExtent: CGFloat
}

/// Shared lazy-reveal engine for LazyHFlow and LazyVFlow.
///
/// Owns the reveal state, scroll geometry, and estimated total size. The caller
/// supplies the scroll axis and the laid-out content for a given item count.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
struct LazyFlowBody<LayoutView: View>: View {
    let count: Int
    let scrollAxis: Axis
    let makeContent: (Int) -> LayoutView

    @State private var numberOfVisible = 1
    @State private var currentExtent: CGFloat = 0
    @State private var scrollMax: CGFloat = 0

    var body: some View {
        // onGeometryChange ships in the Xcode 16 SDK (Swift 6+); Xcode 15 builds fall
        // back to eager rendering since the API does not exist in that SDK.
        #if swift(>=6.0)
            let flowContent = makeContent(numberOfVisible)
            let minExtent: CGFloat? = numberOfVisible < count ? currentExtent / CGFloat(max(1, numberOfVisible)) * CGFloat(count) : nil
            flowContent
                .onGeometryChange(for: LazyFlowGeometry.self) { [scrollAxis] proxy in
                    let bounds = proxy.bounds(of: .scrollView)
                    return LazyFlowGeometry(
                        scrollMax: (scrollAxis == .vertical ? bounds?.maxY : bounds?.maxX) ?? .infinity,
                        contentExtent: proxy.size.value(on: scrollAxis)
                    )
                } action: { values in
                    scrollMax = values.scrollMax
                    currentExtent = values.contentExtent
                    revealMoreIfNeeded()
                }
                .onChange(of: numberOfVisible) {
                    revealMoreIfNeeded()
                }
                .frame(
                    minWidth: scrollAxis == .horizontal ? minExtent : nil,
                    minHeight: scrollAxis == .vertical ? minExtent : nil,
                    alignment: scrollAxis == .horizontal ? .leading : .top
                )
        #else
            makeContent(count).frame(minWidth: nil, minHeight: nil, alignment: scrollAxis == .horizontal ? .leading : .top)
        #endif
    }

    private func revealMoreIfNeeded() {
        numberOfVisible = lazyRevealNext(
            current: numberOfVisible,
            total: count,
            scrollMax: scrollMax,
            contentExtent: currentExtent
        )
    }
}

/// Returns the next `numberOfVisible` value for a lazy-revealing view.
///
/// - Already showing everything → returns `current` unchanged.
/// - No scroll container (infinite scroll max) → jumps straight to `total`.
/// - Content does not yet fill the viewport → increments by 1.
/// - Content already fills the viewport → returns `current` unchanged.
func lazyRevealNext(current: Int, total: Int, scrollMax: CGFloat, contentExtent: CGFloat) -> Int {
    guard current < total else { return current }
    if scrollMax.isInfinite { return total }
    if scrollMax > contentExtent { return current + 1 }
    return current
}
