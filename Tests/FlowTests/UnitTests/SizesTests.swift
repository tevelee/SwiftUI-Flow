import CoreFoundation
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct SizesTests {
    @Test func emptyInput_returnsNil() {
        #expect(sizes(of: [], availableSpace: 100) == nil)
    }

    @Test func singleRigidItem_fitsExactly() throws {
        let items = indexed([MeasuredItem(size: 100 ... 100, spacing: 0)])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items == [WrappedItem(index: 0, size: 100, leadingSpace: 0)])
        #expect(result.remainingSpace == 0)
    }

    @Test func singleRigidItem_withRemainingSpace() throws {
        let items = indexed([MeasuredItem(size: 50 ... 50, spacing: 0)])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items == [WrappedItem(index: 0, size: 50, leadingSpace: 0)])
        #expect(result.remainingSpace == 50)
    }

    @Test func totalSizeExceedsSpace_returnsNil() {
        let items = indexed([
            MeasuredItem(size: 60 ... 60, spacing: 0),
            MeasuredItem(size: 60 ... 60, spacing: 0),
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func spacingCausesOverflow_returnsNil() {
        let items = indexed([
            MeasuredItem(size: 50 ... 50, spacing: 0),
            MeasuredItem(size: 50 ... 50, spacing: 10),
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func firstItemLeadingSpace_alwaysZero() throws {
        let items = indexed([MeasuredItem(size: 50 ... 50, spacing: 20)])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items[0].leadingSpace == 0)
    }

    @Test func lineBreak_atPosition0_allowed() throws {
        let items: IndexedMeasuredItems = [
            (offset: 0, element: MeasuredItem(size: 0 ... 0, spacing: 0, isLineBreakView: true)),
            (offset: 1, element: MeasuredItem(size: 30 ... 30, spacing: 10)),
        ]
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items[1].leadingSpace == 0, "Spacing after line break should be zeroed")
    }

    @Test func lineBreak_atPosition0_withOnlyMarker_returnsZeroSizedLine() throws {
        let items: IndexedMeasuredItems = [
            (offset: 0, element: MeasuredItem(size: 0 ... 0, spacing: 12, isLineBreakView: true))
        ]
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items == [WrappedItem(index: 0, size: 0, leadingSpace: 0)])
        #expect(result.remainingSpace == 100)
    }

    @Test func lineBreak_atNonZeroPosition_returnsNil() {
        let items: IndexedMeasuredItems = [
            (offset: 0, element: MeasuredItem(size: 30 ... 30, spacing: 0)),
            (offset: 1, element: MeasuredItem(size: 0 ... 0, spacing: 0, isLineBreakView: true)),
        ]
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func newLine_atFirstPosition_allowed() throws {
        let items = indexed([
            MeasuredItem(size: 30 ... 30, spacing: 0, shouldStartInNewLine: true)
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items == [WrappedItem(index: 0, size: 30, leadingSpace: 0)])
    }

    @Test func newLine_notAtFirstPosition_returnsNil() {
        let items = indexed([
            MeasuredItem(size: 30 ... 30, spacing: 0),
            MeasuredItem(size: 30 ... 30, spacing: 10, shouldStartInNewLine: true),
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func twoNewLines_returnsNil() {
        let items = indexed([
            MeasuredItem(size: 10 ... 10, spacing: 0, shouldStartInNewLine: true),
            MeasuredItem(size: 10 ... 10, spacing: 10, shouldStartInNewLine: true),
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func maximumFlex_fitsInRemainingSpace() throws {
        let items = indexed([
            MeasuredItem(size: 30 ... 30, spacing: 0),
            MeasuredItem(size: 20 ... 50, spacing: 10, flexibility: .maximum),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items[1].size == 50)
    }

    @Test func maximumFlex_exceedsRemainingSpace_returnsNil() {
        let items = indexed([
            MeasuredItem(size: 60 ... 60, spacing: 0),
            MeasuredItem(size: 20 ... 100, spacing: 10, flexibility: .maximum),
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func minimumFlex_getsNoGrowth() throws {
        let items = indexed([
            MeasuredItem(size: 20 ... 50, spacing: 0, flexibility: .minimum)
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items[0].size == 20)
        #expect(result.remainingSpace == 80)
    }

    @Test func priorityDistribution_higherFirst() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 50, spacing: 0, priority: 1, flexibility: .natural),
            MeasuredItem(size: 10 ... 50, spacing: 10, priority: 0, flexibility: .natural),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items[0].size == 50, "Higher priority item should grow fully")
        #expect(result.items[1].size == 40, "Lower priority item gets remaining")
    }

    @Test func samePriority_proportionalSplit() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 30, spacing: 0, flexibility: .natural),
            MeasuredItem(size: 10 ... 50, spacing: 10, flexibility: .natural),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(result.items[0].size == 30, "Smaller potential fills first")
        #expect(result.items[1].size == 50, "Larger potential gets remainder")
    }

    @Test func samePriority_threeItems_distributesRemainingSpaceByGrowthPotential() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 20, spacing: 0, flexibility: .natural),
            MeasuredItem(size: 10 ... 30, spacing: 0, flexibility: .natural),
            MeasuredItem(size: 10 ... 50, spacing: 0, flexibility: .natural),
        ])
        let result = try #require(sizes(of: items, availableSpace: 80))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 20, leadingSpace: 0),
                WrappedItem(index: 1, size: 30, leadingSpace: 0),
                WrappedItem(index: 2, size: 30, leadingSpace: 0),
            ]
        )
        #expect(result.remainingSpace == 0)
    }

    @Test func multipleFlexItems_allGrow() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 40, spacing: 0, flexibility: .natural),
            MeasuredItem(size: 10 ... 40, spacing: 10, flexibility: .natural),
            MeasuredItem(size: 10 ... 40, spacing: 10, flexibility: .natural),
        ])
        let result = try #require(sizes(of: items, availableSpace: 80))
        #expect(result.items[0].size == 20)
        #expect(result.items[1].size == 20)
        #expect(result.items[2].size == 20)
        #expect(result.remainingSpace == 0)
    }

    @Test func allFlexible_evenSplit() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 50, spacing: 0, flexibility: .natural),
            MeasuredItem(size: 10 ... 50, spacing: 10, flexibility: .natural),
        ])
        let result = try #require(sizes(of: items, availableSpace: 70))
        #expect(result.items[0].size == 30)
        #expect(result.items[1].size == 30)
        #expect(result.remainingSpace == 0)
    }

    @Test func threePriorityLevels() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 40, spacing: 0, priority: 2, flexibility: .natural),
            MeasuredItem(size: 10 ... 40, spacing: 10, priority: 1, flexibility: .natural),
            MeasuredItem(size: 10 ... 40, spacing: 10, priority: 0, flexibility: .natural),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 40, leadingSpace: 0),
                WrappedItem(index: 1, size: 30, leadingSpace: 10),
                WrappedItem(index: 2, size: 10, leadingSpace: 10),
            ],
            "Higher priorities consume remaining growth before lower priorities"
        )
        #expect(result.remainingSpace == 0)
    }

    @Test func maximumFlexAloneOnLine() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 100, spacing: 0, flexibility: .maximum)
        ])
        let result = try #require(sizes(of: items, availableSpace: 80))
        #expect(result.items[0].size == 80)
        #expect(result.remainingSpace == 0)
    }

    @Test func zeroSpacingItems() throws {
        let items = indexed([
            MeasuredItem(size: 20 ... 20, spacing: 0),
            MeasuredItem(size: 20 ... 20, spacing: 0),
            MeasuredItem(size: 20 ... 20, spacing: 0),
        ])
        let result = try #require(sizes(of: items, availableSpace: 60))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 20, leadingSpace: 0),
                WrappedItem(index: 1, size: 20, leadingSpace: 0),
                WrappedItem(index: 2, size: 20, leadingSpace: 0),
            ]
        )
        #expect(result.remainingSpace == 0)
    }

    @Test func negativeSpacing_canAllowRigidSizesToOverlapWithinAvailableSpace() throws {
        let items = indexed([
            MeasuredItem(size: 60 ... 60, spacing: 0),
            MeasuredItem(size: 60 ... 60, spacing: -30),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 60, leadingSpace: 0),
                WrappedItem(index: 1, size: 60, leadingSpace: -30),
            ]
        )
        #expect(result.remainingSpace == 10)
    }

    @Test func fractionalSizesAndSpacing_preserveFractionalRemainingSpace() throws {
        let items = indexed([
            MeasuredItem(size: 1.25 ... 1.25, spacing: 0),
            MeasuredItem(size: 2.5 ... 2.5, spacing: 0.25),
        ])
        let result = try #require(sizes(of: items, availableSpace: 5))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 1.25, leadingSpace: 0),
                WrappedItem(index: 1, size: 2.5, leadingSpace: 0.25),
            ]
        )
        #expect(result.remainingSpace == 1)
    }

    @Test func negativeAvailableSpace_returnsNil() {
        let items = indexed([MeasuredItem(size: 1 ... 1, spacing: 0)])
        #expect(sizes(of: items, availableSpace: -1) == nil)
    }

    @Test func infiniteAvailableSpace_keepsRigidItemsFiniteAndLeavesInfiniteRemainder() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 10, spacing: 0),
            MeasuredItem(size: 20 ... 20, spacing: 5),
        ])
        let result = try #require(sizes(of: items, availableSpace: .infinity))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 10, leadingSpace: 0),
                WrappedItem(index: 1, size: 20, leadingSpace: 5),
            ]
        )
        #expect(result.remainingSpace == .infinity)
    }

    @Test func exactFit_withFloatingPointError_stillFits() throws {
        // 0.1 + 0.1 + 0.1 == 0.30000000000000004 in binary floating point, which is
        // strictly greater than 0.3. A naive `>` comparison would wrap the last item.
        let items = indexed([
            MeasuredItem(size: 0.1 ... 0.1, spacing: 0),
            MeasuredItem(size: 0.1 ... 0.1, spacing: 0),
            MeasuredItem(size: 0.1 ... 0.1, spacing: 0),
        ])
        let result = try #require(sizes(of: items, availableSpace: 0.3))
        #expect(result.items.count == 3)
    }

    @Test func genuineOverflow_beyondTolerance_returnsNil() {
        // Well above any floating-point tolerance: must still report as not fitting.
        let items = indexed([
            MeasuredItem(size: 0.2 ... 0.2, spacing: 0),
            MeasuredItem(size: 0.2 ... 0.2, spacing: 0),
        ])
        #expect(sizes(of: items, availableSpace: 0.3) == nil)
    }

    @Test func twoMaximumFlex_collectivelyExceedSpace_returnsNil() {
        // Each item alone could grow to 60 within the 80pt of remaining space, but
        // their combined growth (50 + 50) cannot, so they must not share a line.
        let items = indexed([
            MeasuredItem(size: 10 ... 60, spacing: 0, flexibility: .maximum),
            MeasuredItem(size: 10 ... 60, spacing: 0, flexibility: .maximum),
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func twoMaximumFlex_collectivelyFit_allowed() throws {
        // Combined growth (20 + 20) fits within the 80pt of remaining space.
        let items = indexed([
            MeasuredItem(size: 10 ... 30, spacing: 0, flexibility: .maximum),
            MeasuredItem(size: 10 ... 30, spacing: 0, flexibility: .maximum),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 30, leadingSpace: 0),
                WrappedItem(index: 1, size: 30, leadingSpace: 0),
            ]
        )
        #expect(result.remainingSpace == 40)
    }

    @Test func twoMaximumFlex_collectivelyFitWithSpacing_allowed() throws {
        let items = indexed([
            MeasuredItem(size: 10 ... 30, spacing: 0, flexibility: .maximum),
            MeasuredItem(size: 10 ... 30, spacing: 10, flexibility: .maximum),
        ])
        let result = try #require(sizes(of: items, availableSpace: 100))
        #expect(
            result.items == [
                WrappedItem(index: 0, size: 30, leadingSpace: 0),
                WrappedItem(index: 1, size: 30, leadingSpace: 10),
            ]
        )
        #expect(result.remainingSpace == 30)
    }
}

private func indexed(_ items: [MeasuredItem]) -> IndexedMeasuredItems {
    Array(items.enumerated())
}

/// Sizes a candidate line through ``LineSizer`` — the unit under test here.
private func sizes(of items: IndexedMeasuredItems, availableSpace: CGFloat) -> SizedLine? {
    LineSizer(availableSpace: availableSpace).sizes(of: items)
}
