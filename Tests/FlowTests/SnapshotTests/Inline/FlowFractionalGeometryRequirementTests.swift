import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowFractionalGeometryRequirementTests {
    @Test func HFlow_fractionalSpacingAndProposal_wrapsRowsWithExactGeometry() {
        let result = FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .top, horizontalSpacing: 0.5, verticalSpacing: 0.25),
            subviews: [1.5 × 1.25, 2 × 1.25, 1 × 1.25],
            proposal: 4.25 × 10
        )
        .layoutThatFits()

        #expect(result.reportedSize == (4 × 2.75))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1.5 × 1.25),
                .init(position: (2, 0), size: 2 × 1.25),
                .init(position: (0, 1.5), size: 1 × 1.25),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 4×2.75
            placements:
            A[0]: origin: 0×0, size: 1.5×1.25
            B[1]: origin: 2×0, size: 2×1.25
            C[2]: origin: 0×1.5, size: 1×1.25
            """
        }
    }

    @Test func VFlow_fractionalSpacingAndProposal_wrapsColumnsWithExactGeometry() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalAlignment: .leading, horizontalSpacing: 0.25, verticalSpacing: 0.5),
            subviews: [1.25 × 1.5, 1.25 × 2, 1.25 × 1],
            proposal: 10 × 4.25
        )
        .layoutThatFits()

        #expect(result.reportedSize == (2.75 × 4))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1.25 × 1.5),
                .init(position: (0, 2), size: 1.25 × 2),
                .init(position: (1.5, 0), size: 1.25 × 1),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 2.75×4
            placements:
            A[0]: origin: 0×0, size: 1.25×1.5
            B[1]: origin: 0×2, size: 1.25×2
            C[2]: origin: 1.5×0, size: 1.25×1
            """
        }
    }

    @Test func HFlow_fractionalCrossAxisAlignment_centersSubviewInRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .center, horizontalSpacing: 0.5, verticalSpacing: 0),
            subviews: [1 × 2.5, 1 × 1.5],
            proposal: 10 × 10
        )
        .layoutThatFits()

        #expect(result.reportedSize == (2.5 × 2.5))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 2.5),
                .init(position: (1.5, 0.5), size: 1 × 1.5),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 2.5×2.5
            placements:
            A[0]: origin: 0×0, size: 1×2.5
            B[1]: origin: 1.5×0.5, size: 1×1.5
            """
        }
    }

    @Test func VFlow_fractionalCrossAxisAlignment_centersSubviewInColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0.5),
            subviews: [2.5 × 1, 1.5 × 1],
            proposal: 10 × 10
        )
        .layoutThatFits()

        #expect(result.reportedSize == (2.5 × 2.5))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 2.5 × 1),
                .init(position: (0.5, 1.5), size: 1.5 × 1),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 2.5×2.5
            placements:
            A[0]: origin: 0×0, size: 2.5×1
            B[1]: origin: 0.5×1.5, size: 1.5×1
            """
        }
    }
}
