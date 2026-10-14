#if os(macOS)
    import AppKit
    import SwiftUI
    import Testing

    @testable import Flow

    // MARK: - Helpers

    private struct Item: Identifiable {
        let id: Int
    }

    private func items(_ count: Int, startingAt offset: Int = 0) -> [Item] {
        (0 ..< count).map { Item(id: $0 + offset) }
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

    // MARK: - LazyHFlow Layout Tests

    @Suite(.tags(.requirements, .lazyLayout))
    @MainActor
    struct LazyHFlowLayoutTests {
        // Outside a ScrollView, LazyHFlow renders all items eagerly — same as HFlow.

        @Test func emptyCollection_producesZeroHeight() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            let h = measuredHeight(
                of: LazyHFlow(data: [Item](), spacing: 8) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 400
            )
            #expect(h == 0)
        }

        @Test func moreItems_producesMoreRows_andGreaterHeight() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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

        @Test func justified_matchesEagerHFlow() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // LazyHFlow must forward `justified` to the underlying HFlowLayout.
            let spacing: CGFloat = 8
            let width: CGFloat = 300

            let eagerHeight = measuredHeight(
                of: HFlow(spacing: spacing, justified: true) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: width
            )
            let lazyHeight = measuredHeight(
                of: LazyHFlow(data: items(10), spacing: spacing, justified: true) { _ in Color.clear.frame(width: 50, height: 50) },
                width: width
            )
            #expect(lazyHeight == eagerHeight)
        }

        @Test func dataFullAlignmentInit_separateHorizontalAndVerticalSpacing() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyHFlow(data:horizontalAlignment:verticalAlignment:horizontalSpacing:verticalSpacing:).
            // 7 items of 50pt in 300pt → row1: 6, row2: 1 → 2 rows.
            let h = measuredHeight(
                of: LazyHFlow(
                    data: items(7),
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 0
                ) { _ in Color.clear.frame(width: 50, height: 50) },
                width: 300
            )
            #expect(h == 100)
        }

        @Test func viewBuilderSpacingInit_matchesDataInit() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyHFlow(spacing:content:) — ViewBuilder uniform-spacing init.
            // Outside a ScrollView it renders all ForEach items eagerly, matching HFlow.
            let spacing: CGFloat = 8
            let width: CGFloat = 300

            let eagerHeight = measuredHeight(
                of: HFlow(spacing: spacing) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: width
            )
            let lazyHeight = measuredHeight(
                of: LazyHFlow(spacing: spacing) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: width
            )
            #expect(lazyHeight == eagerHeight)
        }

        @Test func viewBuilderSeparateSpacingInit_rowSpacingAffectsHeight() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyHFlow(itemSpacing:rowSpacing:content:) — ViewBuilder separate-spacing init.
            // 7 items of 50pt in 300pt → row1: 6, row2: 1 → rowSpacing bridges the two rows.
            let hNoRowSpacing = measuredHeight(
                of: LazyHFlow(itemSpacing: 0, rowSpacing: 0) {
                    ForEach(0 ..< 7, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: 300
            )
            let hWithRowSpacing = measuredHeight(
                of: LazyHFlow(itemSpacing: 0, rowSpacing: 20) {
                    ForEach(0 ..< 7, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: 300
            )
            #expect(hNoRowSpacing == 100)
            #expect(hWithRowSpacing == 120)
        }

        @Test func viewBuilderFullAlignmentInit_producesCorrectHeight() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyHFlow(horizontalAlignment:verticalAlignment:horizontalSpacing:verticalSpacing:content:).
            // 7 items of 50pt in 300pt with zero spacing → 6+1 = 2 rows of 50pt each.
            let h = measuredHeight(
                of: LazyHFlow(
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 0
                ) {
                    ForEach(0 ..< 7, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                width: 300
            )
            #expect(h == 100)
        }
    }

    // MARK: - LazyVFlow Layout Tests

    @Suite(.tags(.requirements, .lazyLayout))
    @MainActor
    struct LazyVFlowLayoutTests {
        // Outside a ScrollView, LazyVFlow renders all items eagerly — same as VFlow.

        @Test func emptyCollection_producesZeroWidth() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            let w = measuredWidth(
                of: LazyVFlow(data: [Item](), spacing: 8) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 400
            )
            #expect(w == 0)
        }

        @Test func moreItems_producesMoreColumns_andGreaterWidth() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
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

        @Test func justified_matchesEagerVFlow() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // LazyVFlow must forward `justified` to the underlying VFlowLayout.
            let spacing: CGFloat = 8
            let height: CGFloat = 300

            let eagerWidth = measuredWidth(
                of: VFlow(spacing: spacing, justified: true) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: height
            )
            let lazyWidth = measuredWidth(
                of: LazyVFlow(data: items(10), spacing: spacing, justified: true) { _ in Color.clear.frame(width: 50, height: 50) },
                height: height
            )
            #expect(lazyWidth == eagerWidth)
        }

        @Test func dataFullAlignmentInit_separateHorizontalAndVerticalSpacing() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyVFlow(data:horizontalAlignment:verticalAlignment:horizontalSpacing:verticalSpacing:).
            // 7 items of 50pt in 300pt → col1: 6, col2: 1 → 2 columns.
            let w = measuredWidth(
                of: LazyVFlow(
                    data: items(7),
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 0
                ) { _ in Color.clear.frame(width: 50, height: 50) },
                height: 300
            )
            #expect(w == 100)
        }

        @Test func viewBuilderSpacingInit_matchesDataInit() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyVFlow(spacing:content:) — ViewBuilder uniform-spacing init.
            // Outside a ScrollView it renders all ForEach items eagerly, matching VFlow.
            let spacing: CGFloat = 8
            let height: CGFloat = 300

            let eagerWidth = measuredWidth(
                of: VFlow(spacing: spacing) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: height
            )
            let lazyWidth = measuredWidth(
                of: LazyVFlow(spacing: spacing) {
                    ForEach(0 ..< 10, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: height
            )
            #expect(lazyWidth == eagerWidth)
        }

        @Test func viewBuilderSeparateSpacingInit_columnSpacingAffectsWidth() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyVFlow(itemSpacing:columnSpacing:content:) — ViewBuilder separate-spacing init.
            // 7 items of 50pt in 300pt → col1: 6, col2: 1 → columnSpacing bridges the two columns.
            let wNoColumnSpacing = measuredWidth(
                of: LazyVFlow(itemSpacing: 0, columnSpacing: 0) {
                    ForEach(0 ..< 7, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: 300
            )
            let wWithColumnSpacing = measuredWidth(
                of: LazyVFlow(itemSpacing: 0, columnSpacing: 20) {
                    ForEach(0 ..< 7, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: 300
            )
            #expect(wNoColumnSpacing == 100)
            #expect(wWithColumnSpacing == 120)
        }

        @Test func viewBuilderFullAlignmentInit_producesCorrectWidth() {
            guard #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) else { return }
            // Exercises LazyVFlow(horizontalAlignment:verticalAlignment:horizontalSpacing:verticalSpacing:content:).
            // 7 items of 50pt in 300pt with zero spacing → 6+1 = 2 columns of 50pt each.
            let w = measuredWidth(
                of: LazyVFlow(
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 0
                ) {
                    ForEach(0 ..< 7, id: \.self) { _ in Color.clear.frame(width: 50, height: 50) }
                },
                height: 300
            )
            #expect(w == 100)
        }
    }
    #if swift(>=6.0)
        @Suite(.serialized, .tags(.requirements, .lazyLayout))
        @MainActor
        struct LazyFlowViewportTests {
            @available(macOS 14, *)
            @Test(arguments: [false, true])
            func retainedItemSizeChange_refillsViewportWithoutChangingDataCount(verticalFlow: Bool) async throws {
                let activity = Activity()
                let data = ContentCount()
                let host = NSHostingView(rootView: Scene(verticalFlow: verticalFlow, activity: activity, data: data))
                let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 100, height: 100), styleMask: .borderless, backing: .buffered, defer: true)
                window.contentView = host
                defer { window.contentView = nil }
                let initial = try await waitForLayout(in: host) { activity.visible.count > 1 && activity.contentExtent > 100 }
                try #require(initial)
                let initialCount = activity.visible.count

                data.cellExtent = 20
                let refilled = try await waitForLayout(in: host) { activity.visible.count > initialCount && activity.contentExtent > 100 }
                #expect(refilled)
                #expect(activity.visible.count < 100)
            }

            @available(macOS 14, *)
            @Test(arguments: [false, true])
            func sameCountReorder_replacesTheRevealedPrefix(verticalFlow: Bool) async throws {
                let activity = Activity()
                let data = ContentCount()
                let host = NSHostingView(rootView: Scene(verticalFlow: verticalFlow, activity: activity, data: data))
                let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 100, height: 100), styleMask: .borderless, backing: .buffered, defer: true)
                window.contentView = host
                defer { window.contentView = nil }
                let initial = try await waitForLayout(in: host) { activity.visible.count > 1 && activity.contentExtent > 100 }
                try #require(initial)
                let initialCount = activity.visible.count
                data.reversed = true
                let expected = Set((0 ..< 100).reversed().prefix(initialCount))
                let reordered = try await waitForLayout(in: host) { activity.visible == expected }
                #expect(reordered)
                #expect(activity.contentExtent > 100)
            }

            @available(macOS 14, *)
            @Test(arguments: [false, true])
            func retainedFlow_handlesEmptyShrinkRegrowAndReplacement(verticalFlow: Bool) async throws {
                let activity = Activity()
                let data = ContentCount()
                let host = NSHostingView(rootView: Scene(verticalFlow: verticalFlow, activity: activity, data: data))
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: true
                )
                window.contentView = host
                defer { window.contentView = nil }
                let initial = try await waitForLayout(in: host) { activity.visible.count > 1 && activity.contentExtent > 100 }
                try #require(initial)
                #expect(activity.visible.count < 100)

                data.count = 0
                let emptied = try await waitForLayout(in: host) { activity.visible.isEmpty && activity.contentExtent == 0 }
                try #require(emptied)
                data.count = 1
                let repopulated = try await waitForLayout(in: host) { activity.visible == [0] && activity.contentExtent == 50 }
                try #require(repopulated)
                data.count = 100
                let regrown = try await waitForLayout(in: host) { activity.visible.count > 1 && activity.contentExtent > 100 }
                try #require(regrown)
                #expect(activity.visible.count < 100)

                data.count = 2
                // Hosted ScrollView sizing varies across runtimes. Both cells must be revealed and the
                // old large-data estimate must disappear; their full extent fits within this viewport.
                let shrunk = try await waitForLayout(in: host) {
                    activity.visible == [0, 1] && (50 ... 100).contains(activity.contentExtent)
                }
                try #require(shrunk, "Rendered IDs: \(activity.visible); content extent: \(activity.contentExtent)")
                data.count = 100
                let grownAgain = try await waitForLayout(in: host) { activity.visible.count >= 2 && activity.contentExtent > 100 }
                try #require(grownAgain)
                data.firstID = 1000
                let replaced = try await waitForLayout(in: host) {
                    !activity.visible.isEmpty && activity.visible.allSatisfy { $0 >= 1000 }
                }
                #expect(replaced)
                #expect(activity.visible.count < 100)
                #expect(activity.contentExtent > 100)
            }

            @available(macOS 14, *)
            @Test(arguments: [false, true])
            func dataGrowth_revealsMoreWhenRenderedPrefixHasNotChanged(verticalFlow: Bool) async throws {
                let activity = Activity()
                let data = ContentCount(count: 1)
                let host = NSHostingView(rootView: Scene(verticalFlow: verticalFlow, activity: activity, data: data))
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: true
                )
                window.contentView = host
                defer { window.contentView = nil }
                let initiallyRendered = try await waitForLayout(in: host) {
                    activity.appeared == [0] && activity.contentExtent == 50
                }
                try #require(initiallyRendered)

                // The one-item prefix still measures 50pt after growth. Geometry alone cannot
                // trigger another reveal; the retained view must react to the changed data count.
                data.count = 100
                let filledViewport = try await waitForLayout(in: host) { activity.appeared.count > 1 }

                #expect(filledViewport)
                #expect(activity.appeared.count < 100)
                #expect(activity.contentExtent > 100, "Unrevealed content must remain scrollable")
            }

            @Test(arguments: [false, true])
            func revealsMoreContent_whenScrollViewportGrows(verticalFlow: Bool) async throws {
                guard #available(macOS 14, *) else { return }
                let activity = Activity()
                let host = NSHostingView(rootView: Scene(verticalFlow: verticalFlow, activity: activity))
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: true
                )
                window.contentView = host
                defer { window.contentView = nil }
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(250))

                let initiallyRevealed = activity.appeared.count
                #expect(initiallyRevealed > 0 && initiallyRevealed < 100)
                #expect(activity.contentExtent > 100, "The size estimate must keep unrevealed content scrollable")

                window.setContentSize(NSSize(width: verticalFlow ? 200 : 100, height: verticalFlow ? 100 : 200))
                host.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(250))
                #expect(activity.appeared.count > initiallyRevealed)
                #expect(activity.appeared.count < 100)
                #expect(activity.contentExtent > 200)
            }

            private final class Activity {
                var appeared: Set<Int> = []
                var visible: Set<Int> = []
                var contentExtent: CGFloat = 0
            }

            private final class ContentCount: ObservableObject {
                @Published var count: Int
                @Published var firstID = 0
                @Published var cellExtent: CGFloat = 50
                @Published var reversed = false

                init(count: Int = 100) {
                    self.count = count
                }
            }

            private func waitForLayout(in host: NSView, until condition: () -> Bool) async throws -> Bool {
                let deadline = ContinuousClock.now.advanced(by: .seconds(2))
                while ContinuousClock.now < deadline {
                    host.layoutSubtreeIfNeeded()
                    if condition() { return true }
                    try await Task.sleep(for: .milliseconds(10))
                }
                return condition()
            }

            @available(macOS 14, *)
            private struct Scene: View {
                let verticalFlow: Bool
                let activity: Activity
                @ObservedObject var data = ContentCount()

                var body: some View {
                    ScrollView(verticalFlow ? .horizontal : .vertical) {
                        flow
                            .onGeometryChange(for: CGFloat.self) { [verticalFlow] proxy in
                                verticalFlow ? proxy.size.width : proxy.size.height
                            } action: {
                                activity.contentExtent = $0
                            }
                    }
                }

                @ViewBuilder private var flow: some View {
                    if verticalFlow {
                        LazyVFlow(data: orderedItems, spacing: 0, content: cell)
                    } else {
                        LazyHFlow(data: orderedItems, spacing: 0, content: cell)
                    }
                }

                private func cell(_ item: Item) -> some View {
                    Color.clear.frame(width: data.cellExtent, height: data.cellExtent)
                        .onAppear {
                            activity.appeared.insert(item.id)
                            activity.visible.insert(item.id)
                        }
                        .onDisappear { activity.visible.remove(item.id) }
                }

                private var orderedItems: [Item] {
                    let content = items(data.count, startingAt: data.firstID)
                    return data.reversed ? Array(content.reversed()) : content
                }
            }
        }
    #endif
#endif
