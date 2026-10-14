import Testing

@testable import Flow

@Suite(.tags(.requirements, .lazyLayout, .regression))
struct LazyRevealStateTests {
    @Test func revealProgress_waitsForTheNewPrefixToBeMeasured() {
        var state = LazyRevealState()
        state.update(total: 100, geometry: .init(scrollMax: 100, contentExtent: 50, measuredCount: 1))
        #expect(state.visibleCount(for: 100) == 2)
        #expect(state.estimatedExtent(for: 100) == 5000)

        state.update(total: 100)
        state.update(total: 100, geometry: .init(scrollMax: 100, contentExtent: 50, measuredCount: 1))
        #expect(state.visibleCount(for: 100) == 2, "An earlier measurement cannot reveal another item")
        #expect(state.estimatedExtent(for: 100) == 5000, "Estimate using the measured prefix, not the next prefix")

        state.update(total: 100, geometry: .init(scrollMax: 100, contentExtent: 50, measuredCount: 2))
        #expect(state.visibleCount(for: 100) == 3, "Equal extent still describes a newly measured prefix")
        #expect(state.estimatedExtent(for: 100) == 2500)
        state.update(total: 100, geometry: .init(scrollMax: 100, contentExtent: 150, measuredCount: 3))
        #expect(state.visibleCount(for: 100) == 3)

        state.update(total: 100, geometry: .init(scrollMax: 200, contentExtent: 150, measuredCount: 3))
        #expect(state.visibleCount(for: 100) == 4, "A larger viewport resumes progress")
        state.update(total: 100, geometry: .init(scrollMax: 200, contentExtent: 200, measuredCount: 4))
        #expect(state.visibleCount(for: 100) == 4, "An exactly filled viewport needs no more content")
        #expect(state.estimatedExtent(for: 100) == 5000)
    }

    @Test func emptyShrinkAndRegrow_keepCountsAndEstimatesUsable() {
        var state = LazyRevealState()
        state.update(total: 0, geometry: .init(scrollMax: 50, contentExtent: 0, measuredCount: 0))
        #expect(state.visibleCount(for: 0) == 0)
        #expect(state.estimatedExtent(for: 0) == nil)

        state.update(total: 10)
        #expect(state.visibleCount(for: 10) == 1)
        #expect(state.estimatedExtent(for: 10) == nil, "Empty geometry cannot estimate nonempty content")
        state.update(total: 10, geometry: .init(scrollMax: 50, contentExtent: 20, measuredCount: 1))
        #expect(state.visibleCount(for: 10) == 2)
        #expect(state.estimatedExtent(for: 10) == 200)

        state.update(total: 1)
        #expect(state.visibleCount(for: 1) == 1)
        #expect(state.estimatedExtent(for: 1) == nil)
        state.update(total: 10)
        #expect(state.visibleCount(for: 10) == 2, "Data growth can reuse unchanged one-item geometry")
        #expect(state.estimatedExtent(for: 10) == 200)
    }

    @Test func noScrollViewport_revealsAllContentWithoutAnEstimate() {
        var state = LazyRevealState()
        state.update(total: 20, geometry: .init(scrollMax: .infinity, contentExtent: 50, measuredCount: 1))
        #expect(state.visibleCount(for: 20) == 20)
        #expect(state.estimatedExtent(for: 20) == nil)

        state.update(total: 5)
        #expect(state.visibleCount(for: 5) == 5)
        state.update(total: 30, geometry: .init(scrollMax: .infinity, contentExtent: 250, measuredCount: 5))
        #expect(state.visibleCount(for: 30) == 30)
        #expect(state.estimatedExtent(for: 30) == nil)
    }
}
