import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowWrappingAlignmentRequirementTests {
    @Test func HFlow_defaultWrapping_fillsRowsInOrder() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: repeated(1 × 1, times: 15),
            proposal: 11 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----------+
            |A B C D E F|
            |G H I J K L|
            |M N O      |
            +-----------+
            """
        }
        #expect(result.reportedSize == (11 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 1)
            placed(at: 2, 0, size: 1 × 1)
            placed(at: 4, 0, size: 1 × 1)
            placed(at: 6, 0, size: 1 × 1)
            placed(at: 8, 0, size: 1 × 1)
            placed(at: 10, 0, size: 1 × 1)
            placed(at: 0, 1, size: 1 × 1)
            placed(at: 2, 1, size: 1 × 1)
            placed(at: 4, 1, size: 1 × 1)
            placed(at: 6, 1, size: 1 × 1)
            placed(at: 8, 1, size: 1 × 1)
            placed(at: 10, 1, size: 1 × 1)
            placed(at: 0, 2, size: 1 × 1)
            placed(at: 2, 2, size: 1 × 1)
            placed(at: 4, 2, size: 1 × 1)
        }
    }

    @Test func VFlow_defaultWrapping_fillsColumnsInOrder() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: repeated(1 × 1, times: 16),
            proposal: 6 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------+
            |ADGJMP|
            |BEHKN |
            |CFILO |
            +------+
            """
        }
        #expect(result.reportedSize == (6 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 1)
            placed(at: 0, 1, size: 1 × 1)
            placed(at: 0, 2, size: 1 × 1)
            placed(at: 1, 0, size: 1 × 1)
            placed(at: 1, 1, size: 1 × 1)
            placed(at: 1, 2, size: 1 × 1)
            placed(at: 2, 0, size: 1 × 1)
            placed(at: 2, 1, size: 1 × 1)
            placed(at: 2, 2, size: 1 × 1)
            placed(at: 3, 0, size: 1 × 1)
            placed(at: 3, 1, size: 1 × 1)
            placed(at: 3, 2, size: 1 × 1)
            placed(at: 4, 0, size: 1 × 1)
            placed(at: 4, 1, size: 1 × 1)
            placed(at: 4, 2, size: 1 × 1)
            placed(at: 5, 0, size: 1 × 1)
        }
    }

    @Test func HFlow_wrappingTwoItemsPerRow_reportsExactPlacements() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [2 × 1, 2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            |AA BB|
            |     |
            |CC DD|
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 0, 2, size: 2 × 1)
            placed(at: 3, 2, size: 2 × 1)
        }
    }

    @Test func VFlow_wrappingTwoItemsPerColumn_reportsExactPlacements() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [1 × 2, 1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |A C|
            |A C|
            |   |
            |B D|
            |B D|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 5))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 3, size: 1 × 2)
            placed(at: 2, 0, size: 1 × 2)
            placed(at: 2, 3, size: 1 × 2)
        }
    }

    @Test func HFlow_centerAlignment_offsetsShortFinalRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .center, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            |AA BB|
            |     |
            | CC  |
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 1.5, 2, size: 2 × 1)
        }
    }

    @Test func VFlow_centerAlignment_offsetsNarrowItemWithinColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [1 × 2, 3 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            | A  C|
            | A  C|
            |     |
            |BBB  |
            |BBB  |
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 5))
        expectPlacements(result.subviews) {
            placed(at: 1, 0, size: 1 × 2)
            placed(at: 0, 3, size: 3 × 2)
            placed(at: 4, 0, size: 1 × 2)
        }
    }
}
