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
}
