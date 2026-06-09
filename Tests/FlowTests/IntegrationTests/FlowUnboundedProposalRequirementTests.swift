import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowUnboundedProposalRequirementTests {
    @Test(.tags(.regression)) func HFlow_justifiedUnboundedWidth_reportsFiniteNaturalSize() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [3 × 1, 3 × 1, 3 × 1],
            proposal: ProposedViewSize(width: .infinity, height: 1)
        )
        .assertExpectedSize(11 × 1)
    }

    @Test(.tags(.regression)) func HFlow_infiniteMaxHeightItem_placesWithFiniteCoordinates() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [3 × 1, (3 × 1) ... (3 × inf), 3 × 1],
            proposal: 10 × 5
        )
        .layoutThatFits()

        for (index, subview) in result.subviews.enumerated() {
            let position = subview.placement?.position
            #expect(position?.x.isFinite == true, "Subview \(index) x position must be finite")
            #expect(position?.y.isFinite == true, "Subview \(index) y position must be finite")
        }
    }

    @Test(.tags(.regression)) func HFlow_infiniteMaxWidthItemWithCenterAlignment_placesWithFiniteCoordinates() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [(1 × 1) ... (inf × 1)],
            proposal: ProposedViewSize(width: .infinity, height: 1)
        )
        .layoutThatFits()

        let position = result.subviews[0].placement?.position
        #expect(position?.x.isFinite == true, "x position must be finite")
        #expect(position?.y.isFinite == true, "y position must be finite")
    }

    @Test(.tags(.regression)) func HFlow_distributed_unboundedProposal_reportsNonZeroSize() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: [3 × 2, 4 × 2, 5 × 2],
            proposal: ProposedViewSize(width: .infinity, height: 10)
        )
        .layoutThatFits()
        #expect(result.reportedSize == (14 × 2), "Three items + two 1pt gaps on one line = 14 wide, 2 tall")
    }

    @Test(.tags(.regression)) func HFlow_justified_unboundedWidth_placesItemsAtNaturalPositions() {
        // With infinite width the effective proposal equals the natural size, so
        // justified distribution adds zero extra space — items land at natural positions.
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [3 × 1, 3 × 1, 3 × 1],
            proposal: ProposedViewSize(width: .infinity, height: 1)
        )
        .layoutThatFits()
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 4, 0, size: 3 × 1)
            placed(at: 8, 0, size: 3 × 1)
        }
    }

    @Test(.tags(.regression)) func HFlow_distributed_unspecifiedProposal_reportsNonZeroSize() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: [3 × 2, 4 × 2, 5 × 2],
            proposal: .unspecified
        )
        .layoutThatFits()
        #expect(result.reportedSize == (14 × 2))
    }
}
