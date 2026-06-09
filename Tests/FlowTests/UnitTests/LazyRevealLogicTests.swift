#if os(macOS)
    import Testing

    @testable import Flow

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
#endif
