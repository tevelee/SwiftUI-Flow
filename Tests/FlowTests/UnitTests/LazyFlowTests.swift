#if os(macOS)
    import AppKit
    @testable import Flow
    import SwiftUI
    import Testing

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

    @Suite(.tags(.requirements, .lazyLayout))
    @MainActor
    struct LazyHFlowLayoutTests {
        // LazyHFlow wraps LazyVGrid. Given a fixed width, it fills rows from top to bottom.
        // A wider minimumItemWidth → fewer columns → more rows → taller rendered height.

        @Test func defaultParameters_matchDocumentedMinimumWidthAndSpacing() {
            let hDefault = measuredHeight(
                of: LazyHFlow(data: items(10)) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            let hExplicit = measuredHeight(
                of: LazyHFlow(data: items(10), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(hDefault == 166)
            #expect(hDefault == hExplicit)
        }

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
            #expect(h80 == 166)
            #expect(h40 == 108)
            #expect(h80 > h40)
        }

        @Test func exactColumnThreshold_controlsWrapping() {
            // Two 80pt columns with one 8pt gap fit exactly in 168pt. One point
            // less leaves one column, which wraps the second item to a new row.
            let hAtThreshold = measuredHeight(
                of: LazyHFlow(data: items(2), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 168
            )
            let hBelowThreshold = measuredHeight(
                of: LazyHFlow(data: items(2), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 167
            )
            #expect(hAtThreshold == 50)
            #expect(hBelowThreshold == 108)
            #expect(hAtThreshold < hBelowThreshold)
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
            #expect(hNoSpacing == 100)
            #expect(hWideSpacing == 190)
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
            #expect(h4 == 50)
            #expect(h8 == 108)
            #expect(h4 < h8)
        }

        @Test func arraySliceData_respectsSliceElementCount() {
            // Four slice elements fit on one row at this width; a fifth would wrap.
            let slice = items(5)[1 ..< 5]
            let h = measuredHeight(
                of: LazyHFlow(data: slice, minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(h == 50)
        }

        @Test func emptyCollection_producesZeroHeight() {
            let h = measuredHeight(
                of: LazyHFlow(data: [Item](), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(h == 0)
        }

        @Test func contentHeight_controlsRowHeight() {
            let h20 = measuredHeight(
                of: LazyHFlow(data: items(4), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 20) },
                width: 400
            )
            let h50 = measuredHeight(
                of: LazyHFlow(data: items(4), minimumItemWidth: 80, spacing: 8) { _ in Color.clear.frame(height: 50) },
                width: 400
            )
            #expect(h20 == 20)
            #expect(h50 == 50)
            #expect(h20 < h50)
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
            #expect(hUncapped == 50)
            #expect(hCapped == 45)
            #expect(hCapped < hUncapped)
        }
    }

    // MARK: - LazyVFlow Layout Tests

    @Suite(.tags(.requirements, .lazyLayout))
    @MainActor
    struct LazyVFlowLayoutTests {
        // LazyVFlow wraps LazyHGrid. Given a fixed height, it fills columns from left to right.
        // A taller minimumItemHeight → fewer rows → more columns → wider rendered width.

        @Test func defaultParameters_matchDocumentedMinimumHeightAndSpacing() {
            let wDefault = measuredWidth(
                of: LazyVFlow(data: items(10)) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            let wExplicit = measuredWidth(
                of: LazyVFlow(data: items(10), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(wDefault == 108)
            #expect(wDefault == wExplicit)
        }

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
            #expect(w40 == 108)
            #expect(w80 == 224)
            #expect(w40 < w80)
        }

        @Test func exactRowThreshold_controlsWrapping() {
            // Two 40pt rows with one 8pt gap fit exactly in 88pt. One point
            // less leaves one row, which wraps the second item to a new column.
            let wAtThreshold = measuredWidth(
                of: LazyVFlow(data: items(2), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 88
            )
            let wBelowThreshold = measuredWidth(
                of: LazyVFlow(data: items(2), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 87
            )
            #expect(wAtThreshold == 50)
            #expect(wBelowThreshold == 108)
            #expect(wAtThreshold < wBelowThreshold)
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
            #expect(wNoSpacing == 100)
            #expect(wWideSpacing == 120)
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
            #expect(w6 == 50)
            #expect(w12 == 108)
            #expect(w6 < w12)
        }

        @Test func arraySliceData_respectsSliceElementCount() {
            // Six slice elements fit in one column at this height; a seventh would wrap.
            let slice = items(7)[1 ..< 7]
            let w = measuredWidth(
                of: LazyVFlow(data: slice, minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(w == 50)
        }

        @Test func emptyCollection_producesZeroWidth() {
            let w = measuredWidth(
                of: LazyVFlow(data: [Item](), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(w == 0)
        }

        @Test func contentWidth_controlsColumnWidth() {
            let w20 = measuredWidth(
                of: LazyVFlow(data: items(6), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 20) },
                height: 320
            )
            let w50 = measuredWidth(
                of: LazyVFlow(data: items(6), minimumItemHeight: 40, spacing: 8) { _ in Color.clear.frame(width: 50) },
                height: 320
            )
            #expect(w20 == 20)
            #expect(w50 == 50)
            #expect(w20 < w50)
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
            #expect(wUncapped == 50)
            #expect(wCapped == 45)
            #expect(wCapped < wUncapped)
        }
    }
#endif
