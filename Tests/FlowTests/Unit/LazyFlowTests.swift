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

    /// Fixes the view's width to `width` via .frame, then returns the natural height via fittingSize.
    @MainActor
    private func measuredHeight(of view: some View, width: CGFloat) -> CGFloat {
        NSHostingView(rootView: AnyView(view.frame(width: width))).fittingSize.height
    }

    /// Fixes the view's height to `height` via .frame, then returns the natural width via fittingSize.
    @MainActor
    private func measuredWidth(of view: some View, height: CGFloat) -> CGFloat {
        NSHostingView(rootView: AnyView(view.frame(height: height))).fittingSize.width
    }

    // MARK: - LazyHFlow Layout Tests

    @Suite
    @MainActor
    struct LazyHFlowLayoutTests {
        // LazyHFlow wraps LazyVGrid. Given a fixed width, it fills rows from top to bottom.
        // A wider minimumItemWidth → fewer columns → more rows → taller rendered height.

        @Test func largerMinimumItemWidth_producesFewerColumns_andTallerLayout() {
            // At 400pt wide with spacing 8:
            //   minimumItemWidth 80 → 4 cols → 3 rows (10 items) → taller
            //   minimumItemWidth 40 → 8 cols → 2 rows (10 items) → shorter
            let h80 = measuredHeight(
                of: LazyHFlow(data: items(10), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            let h40 = measuredHeight(
                of: LazyHFlow(data: items(10), minimumItemWidth: 40, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(h80 > h40)
        }

        @Test func largerSpacing_increasesHeight() {
            // At 400pt wide, minimumItemWidth 80:
            //   spacing 0 → 5 cols → 2 rows → no row gap
            //   spacing 20 → 4 cols → 3 rows → row gaps add up
            let hNoSpacing = measuredHeight(
                of: LazyHFlow(data: items(10), minimumItemWidth: 80, spacing: 0) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            let hWideSpacing = measuredHeight(
                of: LazyHFlow(data: items(10), minimumItemWidth: 80, spacing: 20) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(hNoSpacing < hWideSpacing)
        }

        @Test func moreItems_producesMoreRows_andGreaterHeight() {
            // 4 items → 1 row; 8 items → 2 rows at 4-col layout
            let h4 = measuredHeight(
                of: LazyHFlow(data: items(4), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            let h8 = measuredHeight(
                of: LazyHFlow(data: items(8), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(h4 < h8)
        }

        @Test func emptyCollection_producesZeroHeight() {
            let h = measuredHeight(
                of: LazyHFlow(data: [Item](), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(h == 0)
        }

        @Test func maximumItemWidth_capsColumnWidth() {
            // 3 items in 300pt, minimum=80, spacing=0 → 3 natural columns of 100pt each.
            // With maximum=90, each column is capped at 90pt.
            // Items with a 2:1 aspect ratio have height = width / 2, so capped rows are shorter.
            //   uncapped: col=100pt → item height=50pt → total height=50
            //   capped:   col= 90pt → item height=45pt → total height=45
            let hUncapped = measuredHeight(
                of: LazyHFlow(data: items(3), minimumItemWidth: 80, maximumItemWidth: .infinity, spacing: 0) { _ in
                    Color.clear.aspectRatio(2, contentMode: .fit)
                },
                width: 300
            )
            let hCapped = measuredHeight(
                of: LazyHFlow(data: items(3), minimumItemWidth: 80, maximumItemWidth: 90, spacing: 0) { _ in
                    Color.clear.aspectRatio(2, contentMode: .fit)
                },
                width: 300
            )
            #expect(hCapped < hUncapped)
        }
    }

    // MARK: - LazyVFlow Layout Tests

    @Suite
    @MainActor
    struct LazyVFlowLayoutTests {
        // LazyVFlow wraps LazyHGrid. Given a fixed height, it fills columns from left to right.
        // A taller minimumItemHeight → fewer rows → more columns → wider rendered width.

        @Test func largerMinimumItemHeight_producesFewerRows_andWiderLayout() {
            // At 320pt height with spacing 8:
            //   minimumItemHeight 40 → 6 rows → 2 cols (10 items) → narrower
            //   minimumItemHeight 80 → 3 rows → 4 cols (10 items) → wider
            let w40 = measuredWidth(
                of: LazyVFlow(data: items(10), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            let w80 = measuredWidth(
                of: LazyVFlow(data: items(10), minimumItemHeight: 80, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(w40 < w80)
        }

        @Test func largerSpacing_increasesWidth() {
            // At 320pt height, minimumItemHeight 40:
            //   both spacings produce 2 columns — wider spacing adds column gap
            let wNoSpacing = measuredWidth(
                of: LazyVFlow(data: items(10), minimumItemHeight: 40, spacing: 0) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            let wWideSpacing = measuredWidth(
                of: LazyVFlow(data: items(10), minimumItemHeight: 40, spacing: 20) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(wNoSpacing < wWideSpacing)
        }

        @Test func moreItems_producesMoreColumns_andGreaterWidth() {
            // At 320pt height (6 rows): 6 items → 1 col; 12 items → 2 cols
            let w6 = measuredWidth(
                of: LazyVFlow(data: items(6), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            let w12 = measuredWidth(
                of: LazyVFlow(data: items(12), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(w6 < w12)
        }

        @Test func emptyCollection_producesZeroWidth() {
            let w = measuredWidth(
                of: LazyVFlow(data: [Item](), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(w == 0)
        }

        @Test func maximumItemHeight_capsRowHeight() {
            // 3 items in 300pt height, minimum=80, spacing=0 → 3 natural rows of 100pt each.
            // With maximum=90, each row is capped at 90pt.
            // Items with a 1:2 aspect ratio have width = height / 2, so capped columns are narrower.
            //   uncapped: row=100pt → item width=50pt → total width=50
            //   capped:   row= 90pt → item width=45pt → total width=45
            let wUncapped = measuredWidth(
                of: LazyVFlow(data: items(3), minimumItemHeight: 80, maximumItemHeight: .infinity, spacing: 0) { _ in
                    Color.clear.aspectRatio(0.5, contentMode: .fit)
                },
                height: 300
            )
            let wCapped = measuredWidth(
                of: LazyVFlow(data: items(3), minimumItemHeight: 80, maximumItemHeight: 90, spacing: 0) { _ in
                    Color.clear.aspectRatio(0.5, contentMode: .fit)
                },
                height: 300
            )
            #expect(wCapped < wUncapped)
        }
    }
#endif
