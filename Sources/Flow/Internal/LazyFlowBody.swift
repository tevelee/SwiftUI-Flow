import SwiftUI

struct LazyFlowGeometry: Equatable, Sendable {
    var scrollMax: CGFloat
    var contentExtent: CGFloat
}

/// Shared lazy-reveal engine for LazyHFlow and LazyVFlow.
///
/// All lazy state lives here. The caller supplies the laid-out content for a
/// given item count, a geometry transform for the scroll axis, and a modifier
/// factory that applies the estimated total size hint to the revealed content.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
struct LazyFlowBody<LayoutView: View, SizeModifier: ViewModifier>: View {
    let count: Int
    let geometryTransform: @Sendable (GeometryProxy) -> LazyFlowGeometry
    let makeSizeModifier: (CGFloat?) -> SizeModifier
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
                .onGeometryChange(for: LazyFlowGeometry.self) { [geometryTransform] proxy in
                    geometryTransform(proxy)
                } action: { values in
                    scrollMax = values.scrollMax
                    currentExtent = values.contentExtent
                    revealMoreIfNeeded()
                }
                .onChange(of: numberOfVisible) {
                    revealMoreIfNeeded()
                }
                .modifier(makeSizeModifier(minExtent))
        #else
            makeContent(count).modifier(makeSizeModifier(nil))
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
