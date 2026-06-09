import SwiftUI
import Testing

@testable import Flow

extension FlowUnboundedProposalRequirementTests {
    @Test func HFlow_nilWidthFiniteHeight_placesItemsInOneUnboundedRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 2, 4 × 2, 5 × 2],
            proposal: ProposedViewSize(width: nil, height: 2)
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
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 2),
                .init(position: (4, 0), size: 4 × 2),
                .init(position: (9, 0), size: 5 × 2),
            ]
        )
    }

    @Test func VFlow_finiteWidthNilHeight_placesItemsInOneUnboundedColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [2 × 3, 2 × 4, 2 × 5],
            proposal: ProposedViewSize(width: 2, height: nil)
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
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 2 × 3),
                .init(position: (0, 4), size: 2 × 4),
                .init(position: (0, 9), size: 2 × 5),
            ]
        )
    }

    @Test(.tags(.regression)) func VFlow_unboundedProposal_usesFiniteBoundsHeightForColumnBreaking() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: repeated(2 × 1, times: 8),
            proposal: .unspecified,
            bounds: CGRect(x: 0, y: 0, width: 2, height: 5)
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AA|
            |BB|
            |CC|
            |DD|
            |EE|
            |  |
            |  |
            |  |
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 8))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (0, 1), size: 2 × 1),
                .init(position: (0, 2), size: 2 × 1),
                .init(position: (0, 3), size: 2 × 1),
                .init(position: (0, 4), size: 2 × 1),
                .init(position: (2, 0), size: 2 × 1),
                .init(position: (2, 1), size: 2 × 1),
                .init(position: (2, 2), size: 2 × 1),
            ]
        )
    }

    @Test(.tags(.regression)) func HFlow_unboundedProposal_usesFiniteBoundsWidthForRowBreaking() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: repeated(1 × 2, times: 8),
            proposal: .unspecified,
            bounds: CGRect(x: 0, y: 0, width: 5, height: 2)
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--------+
            |ABCDE   |
            |ABCDE   |
            +--------+
            """
        }
        #expect(result.reportedSize == (8 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (1, 0), size: 1 × 2),
                .init(position: (2, 0), size: 1 × 2),
                .init(position: (3, 0), size: 1 × 2),
                .init(position: (4, 0), size: 1 × 2),
                .init(position: (0, 2), size: 1 × 2),
                .init(position: (1, 2), size: 1 × 2),
                .init(position: (2, 2), size: 1 × 2),
            ]
        )
    }
}
