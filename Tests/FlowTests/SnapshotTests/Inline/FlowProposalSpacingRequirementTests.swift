import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowProposalSpacingRequirementTests {
    @Test func HFlow_infinityProposal_placesItemsInOneRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 2, 4 × 2, 5 × 2],
            proposal: ProposedViewSize(width: .infinity, height: .infinity)
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--------------+
            |AAA BBBB CCCCC|
            |AAA BBBB CCCCC|
            +--------------+
            """
        }
        #expect(result.reportedSize == (14 × 2))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 2)
            placed(at: 4, 0, size: 4 × 2)
            placed(at: 9, 0, size: 5 × 2)
        }
    }

    @Test func VFlow_infinityProposal_placesItemsInOneColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [2 × 3, 2 × 4, 2 × 5],
            proposal: ProposedViewSize(width: .infinity, height: .infinity)
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AA|
            |AA|
            |AA|
            |  |
            |BB|
            |BB|
            |BB|
            |BB|
            |  |
            |CC|
            |CC|
            |CC|
            |CC|
            |CC|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 14))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 3)
            placed(at: 0, 4, size: 2 × 4)
            placed(at: 0, 9, size: 2 × 5)
        }
    }

    @Test func HFlow_zeroProposal_usesMinimumSizes() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 2, 4 × 2],
            proposal: 0 × 0
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----+
            |AAA |
            |AAA |
            |    |
            |BBBB|
            |BBBB|
            +----+
            """
        }
        #expect(result.reportedSize == (4 × 5))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 2)
            placed(at: 0, 3, size: 4 × 2)
        }
    }

    @Test func VFlow_zeroProposal_usesMinimumSizes() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [2 × 3, 2 × 4],
            proposal: 0 × 0
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            |AA BB|
            |AA BB|
            |AA BB|
            |   BB|
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 4))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 3)
            placed(at: 3, 0, size: 2 × 4)
        }
    }

    @Test func HFlow_negativeSpacing_reducesRowWidth() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: -2, verticalSpacing: 0),
            subviews: [5 × 3, 5 × 3, 5 × 3],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----------+
            |AAA**B**CCC|
            |AAA**B**CCC|
            |AAA**B**CCC|
            +-----------+
            """
        }
        #expect(result.reportedSize == (11 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 5 × 3)
            placed(at: 3, 0, size: 5 × 3)
            placed(at: 6, 0, size: 5 × 3)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 11×3
            placements:
            A[0]: origin: 0×0, size: 5×3
            B[1]: origin: 3×0, size: 5×3
            C[2]: origin: 6×0, size: 5×3
            """
        }
    }

    @Test func VFlow_negativeSpacing_reducesColumnHeight() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: -2),
            subviews: [3 × 5, 3 × 5, 3 × 5],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            |AAA|
            |AAA|
            |***|
            |***|
            |BBB|
            |***|
            |***|
            |CCC|
            |CCC|
            |CCC|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 11))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 5)
            placed(at: 0, 3, size: 3 × 5)
            placed(at: 0, 6, size: 3 × 5)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 3×11
            placements:
            A[0]: origin: 0×0, size: 3×5
            B[1]: origin: 0×3, size: 3×5
            C[2]: origin: 0×6, size: 3×5
            """
        }
    }
}
