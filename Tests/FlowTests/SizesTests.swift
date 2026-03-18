import XCTest
@testable import Flow

private func indexed(_ items: [LineItemInput]) -> IndexedLineBreakingInput {
    Array(items.enumerated())
}

final class SizesTests: XCTestCase {
    func test_emptyInput_returnsNil() {
        let result = sizes(of: [], availableSpace: 100)
        XCTAssertNil(result)
    }

    func test_singleRigidItem_fitsExactly() {
        let items = indexed([LineItemInput(size: 100...100, spacing: 0)])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertEqual(result?.items, [LineItemOutput(index: 0, size: 100, leadingSpace: 0)])
        XCTAssertEqual(result?.remainingSpace, 0)
    }

    func test_singleRigidItem_withRemainingSpace() {
        let items = indexed([LineItemInput(size: 50...50, spacing: 0)])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertEqual(result?.items, [LineItemOutput(index: 0, size: 50, leadingSpace: 0)])
        XCTAssertEqual(result?.remainingSpace, 50)
    }

    func test_totalSizeExceedsSpace_returnsNil() {
        let items = indexed([
            LineItemInput(size: 60...60, spacing: 0),
            LineItemInput(size: 60...60, spacing: 0)
        ])
        XCTAssertNil(sizes(of: items, availableSpace: 100))
    }

    func test_spacingCausesOverflow_returnsNil() {
        let items = indexed([
            LineItemInput(size: 50...50, spacing: 0),
            LineItemInput(size: 50...50, spacing: 10)
        ])
        XCTAssertNil(sizes(of: items, availableSpace: 100))
    }

    func test_firstItemLeadingSpace_alwaysZero() {
        let items = indexed([LineItemInput(size: 50...50, spacing: 20)])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertEqual(result?.items[0].leadingSpace, 0)
    }

    func test_lineBreak_atPosition0_allowed() {
        let items: IndexedLineBreakingInput = [
            (offset: 0, element: LineItemInput(size: 0...0, spacing: 0, isLineBreakView: true)),
            (offset: 1, element: LineItemInput(size: 30...30, spacing: 10))
        ]
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.items[1].leadingSpace, 0, "Spacing after line break should be zeroed")
    }

    func test_lineBreak_atNonZeroPosition_returnsNil() {
        let items: IndexedLineBreakingInput = [
            (offset: 0, element: LineItemInput(size: 30...30, spacing: 0)),
            (offset: 1, element: LineItemInput(size: 0...0, spacing: 0, isLineBreakView: true))
        ]
        XCTAssertNil(sizes(of: items, availableSpace: 100))
    }

    func test_newLine_atFirstPosition_allowed() {
        let items = indexed([
            LineItemInput(size: 30...30, spacing: 0, shouldStartInNewLine: true)
        ])
        XCTAssertNotNil(sizes(of: items, availableSpace: 100))
    }

    func test_newLine_notAtFirstPosition_returnsNil() {
        let items = indexed([
            LineItemInput(size: 30...30, spacing: 0),
            LineItemInput(size: 30...30, spacing: 10, shouldStartInNewLine: true)
        ])
        XCTAssertNil(sizes(of: items, availableSpace: 100))
    }

    func test_twoNewLines_returnsNil() {
        let items = indexed([
            LineItemInput(size: 10...10, spacing: 0, shouldStartInNewLine: true),
            LineItemInput(size: 10...10, spacing: 10, shouldStartInNewLine: true)
        ])
        XCTAssertNil(sizes(of: items, availableSpace: 100))
    }

    func test_maximumFlex_fitsInRemainingSpace() {
        let items = indexed([
            LineItemInput(size: 30...30, spacing: 0),
            LineItemInput(size: 20...50, spacing: 10, flexibility: .maximum)
        ])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.items[1].size, 50)
    }

    func test_maximumFlex_exceedsRemainingSpace_returnsNil() {
        let items = indexed([
            LineItemInput(size: 60...60, spacing: 0),
            LineItemInput(size: 20...100, spacing: 10, flexibility: .maximum)
        ])
        XCTAssertNil(sizes(of: items, availableSpace: 100))
    }

    func test_minimumFlex_getsNoGrowth() {
        let items = indexed([
            LineItemInput(size: 20...50, spacing: 0, flexibility: .minimum)
        ])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertEqual(result?.items[0].size, 20)
        XCTAssertEqual(result?.remainingSpace, 80)
    }

    func test_priorityDistribution_higherFirst() {
        let items = indexed([
            LineItemInput(size: 10...50, spacing: 0, priority: 1, flexibility: .natural),
            LineItemInput(size: 10...50, spacing: 10, priority: 0, flexibility: .natural)
        ])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertEqual(result?.items[0].size, 50, "Higher priority item should grow fully")
        XCTAssertEqual(result?.items[1].size, 40, "Lower priority item gets remaining")
    }

    func test_samePriority_proportionalSplit() {
        let items = indexed([
            LineItemInput(size: 10...30, spacing: 0, flexibility: .natural),
            LineItemInput(size: 10...50, spacing: 10, flexibility: .natural)
        ])
        let result = sizes(of: items, availableSpace: 100)
        XCTAssertEqual(result?.items[0].size, 30, "Smaller potential fills first")
        XCTAssertEqual(result?.items[1].size, 50, "Larger potential gets remainder")
    }

    func test_multipleFlexItems_allGrow() {
        let items = indexed([
            LineItemInput(size: 10...40, spacing: 0, flexibility: .natural),
            LineItemInput(size: 10...40, spacing: 10, flexibility: .natural),
            LineItemInput(size: 10...40, spacing: 10, flexibility: .natural)
        ])
        let result = sizes(of: items, availableSpace: 80)
        XCTAssertEqual(result?.items[0].size, 20)
        XCTAssertEqual(result?.items[1].size, 20)
        XCTAssertEqual(result?.items[2].size, 20)
        XCTAssertEqual(result?.remainingSpace, 0)
    }
}
