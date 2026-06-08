#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    // MARK: - Helpers

    private struct Item: Identifiable {
        let id: Int
    }

    private func items(_ count: Int) -> [Item] {
        (0 ..< count).map { Item(id: $0) }
    }

    /// Renders `view` at `width` inside a deferred NSWindow (off-screen) so
    /// SwiftUI's render pipeline fires onGeometryChange callbacks. Drains the
    /// runloop until the layout stabilises, then returns the final fitted height.
    @MainActor
    private func measuredHeight(of view: some View, width: CGFloat) -> CGFloat {
        let host = NSHostingView(rootView: AnyView(view.frame(width: width)))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 800),
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        window.contentView = host
        var prev = host.fittingSize.height
        for _ in 0 ..< 10 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            let next = host.fittingSize.height
            if next == prev { break }
            prev = next
        }
        return host.fittingSize.height
    }

    /// Same as above but for a fixed height, returning the fitted width.
    @MainActor
    private func measuredWidth(of view: some View, height: CGFloat) -> CGFloat {
        let host = NSHostingView(rootView: AnyView(view.frame(height: height)))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: height),
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )
        window.contentView = host
        var prev = host.fittingSize.width
        for _ in 0 ..< 10 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            let next = host.fittingSize.width
            if next == prev { break }
            prev = next
        }
        return host.fittingSize.width
    }

    // MARK: - Reveal Logic

    @Suite(.tags(.requirements, .lazyLayout, .regression))
    struct LazyRevealLogicTests {
        // Tests the pure `lazyRevealNext` function that drives both LazyHFlow and LazyVFlow.

        @Test func alreadyAtTotal_returnsCurrentUnchanged() {
            #expect(lazyRevealNext(current: 5, total: 5, scrollMax: 300, contentExtent: 100) == 5)
            #expect(lazyRevealNext(current: 10, total: 5, scrollMax: 300, contentExtent: 100) == 10)
        }

        @Test func infiniteScrollMax_jumpsToTotal() {
            #expect(lazyRevealNext(current: 1, total: 20, scrollMax: .infinity, contentExtent: 50) == 20)
        }

        @Test func contentUnderflowsViewport_incrementsOne() {
            // scrollMax (300) > contentExtent (200) → one more item
            #expect(lazyRevealNext(current: 3, total: 10, scrollMax: 300, contentExtent: 200) == 4)
        }

        @Test func contentFillsViewport_returnsCurrentUnchanged() {
            // scrollMax (200) <= contentExtent (300) → already filled
            #expect(lazyRevealNext(current: 5, total: 10, scrollMax: 200, contentExtent: 300) == 5)
        }

        @Test func exactlyFilledViewport_returnsCurrentUnchanged() {
            // scrollMax == contentExtent → viewport is exactly filled, no need to reveal more
            #expect(lazyRevealNext(current: 3, total: 10, scrollMax: 200, contentExtent: 200) == 3)
        }
    }

    // MARK: - LazyHFlow Layout Tests

    @Suite(.tags(.requirements, .lazyLayout))
    @MainActor
    struct LazyHFlowLayoutTests {
        // Outside a ScrollView, LazyHFlow renders all items eagerly — same as HFlow.

        @Test func emptyCollection_producesZeroHeight() {
            let h = measuredHeight(
                of: LazyHFlow(data: [Item](), spacing: 8) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 400
            )
            #expect(h == 0)
        }

        @Test func moreItems_producesMoreRows_andGreaterHeight() {
            // 4 items of 50pt in 280pt → 4 < 5 per row → 1 row → height 50.
            // 7 items of 50pt in 280pt → row1: 5, row2: 2 → height 100.
            let h4 = measuredHeight(
                of: LazyHFlow(data: items(4), spacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 280
            )
            let h7 = measuredHeight(
                of: LazyHFlow(data: items(7), spacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 280
            )
            #expect(h4 == 50)
            #expect(h7 == 100)
        }

        @Test func rowSpacing_increasesHeight() {
            // 7 items of 50pt in 300pt → row1: 6, row2: 1 → row spacing only matters with 2+ rows.
            let hNoSpacing = measuredHeight(
                of: LazyHFlow(data: items(7), itemSpacing: 0, rowSpacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 300
            )
            let hWithSpacing = measuredHeight(
                of: LazyHFlow(data: items(7), itemSpacing: 0, rowSpacing: 20) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 300
            )
            #expect(hNoSpacing == 100)
            #expect(hWithSpacing == 120)
        }

        @Test func itemSpacing_affectsLineBreaking() {
            // itemSpacing=0: 8×50=400 fits exactly in 400pt → 1 row → height 50.
            // itemSpacing=2: 8×50+7×2=414 > 400 → row1: 7, row2: 1 → height 100.
            let h0 = measuredHeight(
                of: LazyHFlow(data: items(8), itemSpacing: 0, rowSpacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 400
            )
            let h2 = measuredHeight(
                of: LazyHFlow(data: items(8), itemSpacing: 2, rowSpacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 400
            )
            #expect(h0 == 50)
            #expect(h2 == 100)
        }

        @Test func matchesEagerHFlow_forFixedSizeItems() {
            // Core correctness guarantee: outside a ScrollView, LazyHFlow
            // should produce identical layout to HFlow.
            let spacing: CGFloat = 8
            let width: CGFloat = 300

            let eagerHeight = measuredHeight(
                of: HFlow(spacing: spacing) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: width
            )
            let lazyHeight = measuredHeight(
                of: LazyHFlow(data: items(10), spacing: spacing) { _ in Color.clear.frame(width: 50, height: 50) },
                width: width
            )
            #expect(lazyHeight == eagerHeight)
        }

        @Test func distributeItemsEvenly_matchesEagerHFlow() {
            // LazyHFlow must forward `distributeItemsEvenly` to the underlying HFlowLayout.
            let spacing: CGFloat = 8
            let width: CGFloat = 300

            let eagerHeight = measuredHeight(
                of: HFlow(spacing: spacing, distributeItemsEvenly: true) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: width
            )
            let lazyHeight = measuredHeight(
                of: LazyHFlow(data: items(10), spacing: spacing, distributeItemsEvenly: true) { _ in Color.clear.frame(width: 50, height: 50) },
                width: width
            )
            #expect(lazyHeight == eagerHeight)
        }
    }

    // MARK: - LazyVFlow Layout Tests

    @Suite(.tags(.requirements, .lazyLayout))
    @MainActor
    struct LazyVFlowLayoutTests {
        // Outside a ScrollView, LazyVFlow renders all items eagerly — same as VFlow.

        @Test func emptyCollection_producesZeroWidth() {
            let w = measuredWidth(
                of: LazyVFlow(data: [Item](), spacing: 8) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 400
            )
            #expect(w == 0)
        }

        @Test func moreItems_producesMoreColumns_andGreaterWidth() {
            // 4 items of 50pt in 280pt → 4 < 5 per column → 1 column → width 50.
            // 7 items of 50pt in 280pt → col1: 5, col2: 2 → width 100.
            let w4 = measuredWidth(
                of: LazyVFlow(data: items(4), spacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 280
            )
            let w7 = measuredWidth(
                of: LazyVFlow(data: items(7), spacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 280
            )
            #expect(w4 == 50)
            #expect(w7 == 100)
        }

        @Test func columnSpacing_increasesWidth() {
            // 7 items of 50pt in 300pt → col1: 6, col2: 1 → column spacing only matters with 2+ columns.
            let wNoSpacing = measuredWidth(
                of: LazyVFlow(data: items(7), itemSpacing: 0, columnSpacing: 0) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 300
            )
            let wWithSpacing = measuredWidth(
                of: LazyVFlow(data: items(7), itemSpacing: 0, columnSpacing: 20) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 300
            )
            #expect(wNoSpacing == 100)
            #expect(wWithSpacing == 120)
        }

        @Test func matchesEagerVFlow_forFixedSizeItems() {
            let spacing: CGFloat = 8
            let height: CGFloat = 300

            let eagerWidth = measuredWidth(
                of: VFlow(spacing: spacing) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: height
            )
            let lazyWidth = measuredWidth(
                of: LazyVFlow(data: items(10), spacing: spacing) { _ in Color.clear.frame(width: 50, height: 50) },
                height: height
            )
            #expect(lazyWidth == eagerWidth)
        }

        @Test func distributeItemsEvenly_matchesEagerVFlow() {
            // LazyVFlow must forward `distributeItemsEvenly` to the underlying VFlowLayout.
            let spacing: CGFloat = 8
            let height: CGFloat = 300

            let eagerWidth = measuredWidth(
                of: VFlow(spacing: spacing, distributeItemsEvenly: true) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: height
            )
            let lazyWidth = measuredWidth(
                of: LazyVFlow(data: items(10), spacing: spacing, distributeItemsEvenly: true) { _ in Color.clear.frame(width: 50, height: 50) },
                height: height
            )
            #expect(lazyWidth == eagerWidth)
        }
    }
#endif
