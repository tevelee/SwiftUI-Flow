import SwiftUI
import Testing

@testable import Flow

extension FlowSizingRequirementTests {
    @Test func HFlow_mixedZeroSizeAndNormalSubviews_countsSpacingAroundZeroSizeSubview() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 2, TestSubview(size: .zero), 3 × 2],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--------+
            |AAA  CCC|
            |AAA  CCC|
            +--------+
            """
        }
        #expect(result.reportedSize == (8 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 2),
                .init(position: (4, 1), size: .zero),
                .init(position: (5, 0), size: 3 × 2),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 8×2
            placements:
            A[0]: origin: 0×0, size: 3×2
            B[1]: origin: 4×1, size: 0×0
            C[2]: origin: 5×0, size: 3×2
            """
        }
    }

    @Test func VFlow_mixedZeroSizeAndNormalSubviews_countsSpacingAroundZeroSizeSubview() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [2 × 3, TestSubview(size: .zero), 2 × 3],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AA|
            |AA|
            |AA|
            |  |
            |  |
            |CC|
            |CC|
            |CC|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 8))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 2 × 3),
                .init(position: (1, 4), size: .zero),
                .init(position: (0, 5), size: 2 × 3),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 2×8
            placements:
            A[0]: origin: 0×0, size: 2×3
            B[1]: origin: 1×4, size: 0×0
            C[2]: origin: 0×5, size: 2×3
            """
        }
    }
}
