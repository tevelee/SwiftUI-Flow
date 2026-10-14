import SwiftUI

/// Shared lazy-reveal engine for LazyHFlow and LazyVFlow.
///
/// Owns the reveal state, scroll geometry, and estimated total size. The caller
/// supplies the scroll axis and the laid-out content for a given item count.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
struct LazyFlowContent<LayoutView: View>: View {
    let count: Int
    let scrollAxis: Axis
    let makeContent: (Int) -> LayoutView

    @State private var reveal = LazyRevealState()

    var body: some View {
        // onGeometryChange ships in the Xcode 16 SDK (Swift 6+); Xcode 15 builds fall
        // back to eager rendering since the API does not exist in that SDK.
        #if swift(>=6.0)
            let revealedItemCount = reveal.revealedItemCount(for: count)
            let minExtent = reveal.estimatedExtent(for: count)
            makeContent(revealedItemCount)
                .onGeometryChange(for: LazyFlowGeometry.self) { [scrollAxis, revealedItemCount] proxy in
                    let bounds = proxy.bounds(of: .scrollView)
                    return LazyFlowGeometry(
                        viewportEnd: (scrollAxis == .vertical ? bounds?.maxY : bounds?.maxX) ?? .infinity,
                        contentExtent: proxy.size.value(on: scrollAxis),
                        measuredItemCount: revealedItemCount
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
