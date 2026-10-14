import SwiftUI

/// Shared lazy-reveal engine for LazyHFlow and LazyVFlow.
///
/// Owns the reveal state, scroll geometry, and estimated total size. The caller
/// supplies the scroll axis and the laid-out content for a given item count.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
struct LazyFlowBody<LayoutView: View>: View {
    let count: Int
    let scrollAxis: Axis
    let makeContent: (Int) -> LayoutView

    @State private var reveal = LazyRevealState()

    var body: some View {
        // onGeometryChange ships in the Xcode 16 SDK (Swift 6+); Xcode 15 builds fall
        // back to eager rendering since the API does not exist in that SDK.
        #if swift(>=6.0)
            let visibleCount = reveal.visibleCount(for: count)
            let minExtent = reveal.estimatedExtent(for: count)
            makeContent(visibleCount)
                .onGeometryChange(for: LazyFlowGeometry.self) { [scrollAxis, visibleCount] proxy in
                    let bounds = proxy.bounds(of: .scrollView)
                    return LazyFlowGeometry(
                        scrollMax: (scrollAxis == .vertical ? bounds?.maxY : bounds?.maxX) ?? .infinity,
                        contentExtent: proxy.size.value(on: scrollAxis),
                        measuredCount: visibleCount
                    )
                } action: { values in
                    reveal.update(total: count, geometry: values)
                }
                .onChange(of: count) {
                    reveal.update(total: count)
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

}
