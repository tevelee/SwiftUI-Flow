import Testing
@testable import Flow

@Suite
struct SizesTests {
    @Test func emptyInput_returnsNil() {
        #expect(sizes(of: [], availableSpace: 100) == nil)
    }

    @Test func singleRigidItem_fitsExactly() {
        let items = indexed([LineItemInput(size: 100...100, spacing: 0)])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result?.items == [LineItemOutput(index: 0, size: 100, leadingSpace: 0)])
        #expect(result?.remainingSpace == 0)
    }

    @Test func singleRigidItem_withRemainingSpace() {
        let items = indexed([LineItemInput(size: 50...50, spacing: 0)])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result?.items == [LineItemOutput(index: 0, size: 50, leadingSpace: 0)])
        #expect(result?.remainingSpace == 50)
    }

    @Test func totalSizeExceedsSpace_returnsNil() {
        let items = indexed([
            LineItemInput(size: 60...60, spacing: 0),
            LineItemInput(size: 60...60, spacing: 0)
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func spacingCausesOverflow_returnsNil() {
        let items = indexed([
            LineItemInput(size: 50...50, spacing: 0),
            LineItemInput(size: 50...50, spacing: 10)
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func firstItemLeadingSpace_alwaysZero() {
        let items = indexed([LineItemInput(size: 50...50, spacing: 20)])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result?.items[0].leadingSpace == 0)
    }

    @Test func lineBreak_atPosition0_allowed() {
        let items: IndexedLineBreakingInput = [
            (offset: 0, element: LineItemInput(size: 0...0, spacing: 0, isLineBreakView: true)),
            (offset: 1, element: LineItemInput(size: 30...30, spacing: 10))
        ]
        let result = sizes(of: items, availableSpace: 100)
        #expect(result != nil)
        #expect(result?.items[1].leadingSpace == 0, "Spacing after line break should be zeroed")
    }

    @Test func lineBreak_atNonZeroPosition_returnsNil() {
        let items: IndexedLineBreakingInput = [
            (offset: 0, element: LineItemInput(size: 30...30, spacing: 0)),
            (offset: 1, element: LineItemInput(size: 0...0, spacing: 0, isLineBreakView: true))
        ]
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func newLine_atFirstPosition_allowed() {
        let items = indexed([
            LineItemInput(size: 30...30, spacing: 0, shouldStartInNewLine: true)
        ])
        #expect(sizes(of: items, availableSpace: 100) != nil)
    }

    @Test func newLine_notAtFirstPosition_returnsNil() {
        let items = indexed([
            LineItemInput(size: 30...30, spacing: 0),
            LineItemInput(size: 30...30, spacing: 10, shouldStartInNewLine: true)
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func twoNewLines_returnsNil() {
        let items = indexed([
            LineItemInput(size: 10...10, spacing: 0, shouldStartInNewLine: true),
            LineItemInput(size: 10...10, spacing: 10, shouldStartInNewLine: true)
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func maximumFlex_fitsInRemainingSpace() {
        let items = indexed([
            LineItemInput(size: 30...30, spacing: 0),
            LineItemInput(size: 20...50, spacing: 10, flexibility: .maximum)
        ])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result != nil)
        #expect(result?.items[1].size == 50)
    }

    @Test func maximumFlex_exceedsRemainingSpace_returnsNil() {
        let items = indexed([
            LineItemInput(size: 60...60, spacing: 0),
            LineItemInput(size: 20...100, spacing: 10, flexibility: .maximum)
        ])
        #expect(sizes(of: items, availableSpace: 100) == nil)
    }

    @Test func minimumFlex_getsNoGrowth() {
        let items = indexed([
            LineItemInput(size: 20...50, spacing: 0, flexibility: .minimum)
        ])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result?.items[0].size == 20)
        #expect(result?.remainingSpace == 80)
    }

    @Test func priorityDistribution_higherFirst() {
        let items = indexed([
            LineItemInput(size: 10...50, spacing: 0, priority: 1, flexibility: .natural),
            LineItemInput(size: 10...50, spacing: 10, priority: 0, flexibility: .natural)
        ])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result?.items[0].size == 50, "Higher priority item should grow fully")
        #expect(result?.items[1].size == 40, "Lower priority item gets remaining")
    }

    @Test func samePriority_proportionalSplit() {
        let items = indexed([
            LineItemInput(size: 10...30, spacing: 0, flexibility: .natural),
            LineItemInput(size: 10...50, spacing: 10, flexibility: .natural)
        ])
        let result = sizes(of: items, availableSpace: 100)
        #expect(result?.items[0].size == 30, "Smaller potential fills first")
        #expect(result?.items[1].size == 50, "Larger potential gets remainder")
    }

    @Test func multipleFlexItems_allGrow() {
        let items = indexed([
            LineItemInput(size: 10...40, spacing: 0, flexibility: .natural),
            LineItemInput(size: 10...40, spacing: 10, flexibility: .natural),
            LineItemInput(size: 10...40, spacing: 10, flexibility: .natural)
        ])
        let result = sizes(of: items, availableSpace: 80)
        #expect(result?.items[0].size == 20)
        #expect(result?.items[1].size == 20)
        #expect(result?.items[2].size == 20)
        #expect(result?.remainingSpace == 0)
    }
}

private func indexed(_ items: [LineItemInput]) -> IndexedLineBreakingInput {
    Array(items.enumerated())
}
