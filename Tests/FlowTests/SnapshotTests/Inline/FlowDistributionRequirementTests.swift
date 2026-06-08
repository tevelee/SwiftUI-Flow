import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowDistributionRequirementTests {
    @Test(.tags(.regression)) func HFlow_justifiedLineBreakMarker_doesNotReceiveDistributedSpace() {
        let subviews: [TestSubview] = [
            3 × 1,
            testLineBreakSubview(),
            3 × 1,
            3 × 1,
        ]

        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: subviews,
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAA       |
            |CCC    DDD|
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 2))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 0, 1.5, size: .zero)
            placed(at: 0, 1, size: 3 × 1)
            placed(at: 7, 1, size: 3 × 1)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 10×2
            placements:
            A[0]: origin: 0×0, size: 3×1
            B[1]: origin: 0×1.5, size: 0×0
            C[2]: origin: 0×1, size: 3×1
            D[3]: origin: 7×1, size: 3×1
            """
        }
    }

    @Test(.tags(.regression)) func VFlow_justifiedLineBreakMarker_doesNotReceiveDistributedSpace() {
        let subviews: [TestSubview] = [
            1 × 3,
            testLineBreakSubview(),
            1 × 3,
            1 × 3,
        ]

        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, justified: true),
            subviews: subviews,
            proposal: 2 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AC|
            |AC|
            |AC|
            |  |
            |  |
            |  |
            |  |
            | D|
            | D|
            | D|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 3)
            placed(at: 1.5, 0, size: .zero)
            placed(at: 1, 0, size: 1 × 3)
            placed(at: 1, 7, size: 1 × 3)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 2×10
            placements:
            A[0]: origin: 0×0, size: 1×3
            B[1]: origin: 1.5×0, size: 0×0
            C[2]: origin: 1×0, size: 1×3
            D[3]: origin: 1×7, size: 1×3
            """
        }
    }

    @Test func HFlow_justifiedRigidLine_distributesRemainingSpaceBetweenVisibleItems() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 10 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AA  BB  CC|
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 1))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 4, 0, size: 2 × 1)
            placed(at: 8, 0, size: 2 × 1)
        }
    }

    @Test func HFlow_justifiedSingleItemLine_keepsItemAtLeadingEdge() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [5 × 1],
            proposal: 10 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAAAA     |
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 1))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 5 × 1)
        }
    }

    @Test func HFlow_justifiedFlexibleItem_consumesRemainingRowWidth() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [3 × 1, 3 × 1 ... inf × 1, 2 × 1],
            proposal: 9 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---------+
            |AAA BBBBB|
            |CC       |
            +---------+
            """
        }
        #expect(result.reportedSize == (9 × 2))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 4, 0, size: 5 × 1)
            placed(at: 0, 1, size: 2 × 1)
        }
    }

    @Test func VFlow_justifiedFlexibleItem_consumesRemainingColumnHeight() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, justified: true),
            subviews: [1 × 3, 1 × 3 ... 1 × inf, 1 × 2],
            proposal: 2 × 9
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AC|
            |AC|
            |A |
            |  |
            |B |
            |B |
            |B |
            |B |
            |B |
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 9))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 3)
            placed(at: 0, 4, size: 1 × 5)
            placed(at: 1, 0, size: 1 × 2)
        }
    }

    @Test func HFlow_justifiedSingleItemLine_keepsOversizedLineNaturalWidth() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
            subviews: [3 × 1, 3 × 1, 8 × 1],
            proposal: 8 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--------+
            |AAA  BBB|
            |CCCCCCCC|
            +--------+
            """
        }
        #expect(result.reportedSize == (8 × 2))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 5, 0, size: 3 × 1)
            placed(at: 0, 1, size: 8 × 1)
        }
    }

    @Test func VFlow_justifiedSingleItemColumn_keepsOversizedColumnNaturalHeight() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, justified: true),
            subviews: [1 × 3, 1 × 3, 1 × 8],
            proposal: 2 × 8
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AC|
            |AC|
            |AC|
            | C|
            | C|
            |BC|
            |BC|
            |BC|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 8))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 3)
            placed(at: 0, 5, size: 1 × 3)
            placed(at: 1, 0, size: 1 × 8)
        }
    }

    @Test func VFlow_justifiedRigidColumn_distributesRemainingSpaceBetweenVisibleItems() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, justified: true),
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 1 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-+
            |A|
            |A|
            | |
            | |
            |B|
            |B|
            | |
            | |
            |C|
            |C|
            +-+
            """
        }
        #expect(result.reportedSize == (1 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 4, size: 1 × 2)
            placed(at: 0, 8, size: 1 × 2)
        }
    }

    @Test func VFlow_justifiedTwoItemColumn_usesItemHeightsForDistributedSpacing() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [2 × 1, 2 × 1],
            proposal: 2 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AA|
            |  |
            |  |
            |  |
            |BB|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 5))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 0, 4, size: 2 × 1)
        }
    }

    @Test func HFlow_distributedFlexibleItem_balancesRowsAfterFlexMeasurement() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: [3 × 1, 3 × 1 ... 6 × 1, 3 × 1],
            proposal: 12 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------------+
            |AAA BBBB CCC|
            +------------+
            """
        }
        #expect(result.reportedSize == (12 × 1))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 4, 0, size: 4 × 1)
            placed(at: 9, 0, size: 3 × 1)
        }
    }

    @Test func HFlow_distributedFractionalSpacing_balancesRowsWithExactGeometry() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0.25, verticalSpacing: 0.25, distributeItemsEvenly: true),
            subviews: repeated(0.5 × 1, times: 8),
            proposal: 5 × 10
        )
        .layoutThatFits()

        #expect(result.reportedSize == (4.25 × 2.25))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 0.5 × 1)
            placed(at: 0.75, 0, size: 0.5 × 1)
            placed(at: 1.5, 0, size: 0.5 × 1)
            placed(at: 2.25, 0, size: 0.5 × 1)
            placed(at: 3, 0, size: 0.5 × 1)
            placed(at: 3.75, 0, size: 0.5 × 1)
            placed(at: 0, 1.25, size: 0.5 × 1)
            placed(at: 0.75, 1.25, size: 0.5 × 1)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 4.25×2.25
            placements:
            A[0]: origin: 0×0, size: 0.5×1
            B[1]: origin: 0.75×0, size: 0.5×1
            C[2]: origin: 1.5×0, size: 0.5×1
            D[3]: origin: 2.25×0, size: 0.5×1
            E[4]: origin: 3×0, size: 0.5×1
            F[5]: origin: 3.75×0, size: 0.5×1
            G[6]: origin: 0×1.25, size: 0.5×1
            H[7]: origin: 0.75×1.25, size: 0.5×1
            """
        }
    }

    @Test func HFlow_distributedNegativeSpacing_balancesOverlappingRowsWithExactPlacements() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: -1, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: repeated(3 × 1, times: 7),
            proposal: 7 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-------+
            |AA*B*CC|
            |DD*EE  |
            |FF*GG  |
            +-------+
            """
        }
        #expect(result.reportedSize == (7 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 2, 0, size: 3 × 1)
            placed(at: 4, 0, size: 3 × 1)
            placed(at: 0, 1, size: 3 × 1)
            placed(at: 2, 1, size: 3 × 1)
            placed(at: 0, 2, size: 3 × 1)
            placed(at: 2, 2, size: 3 × 1)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 7×3
            placements:
            A[0]: origin: 0×0, size: 3×1
            B[1]: origin: 2×0, size: 3×1
            C[2]: origin: 4×0, size: 3×1
            D[3]: origin: 0×1, size: 3×1
            E[4]: origin: 2×1, size: 3×1
            F[5]: origin: 0×2, size: 3×1
            G[6]: origin: 2×2, size: 3×1
            """
        }
    }

    @Test func VFlow_distributedFlexibleItem_balancesColumnsAfterFlexMeasurement() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true),
            subviews: [1 × 3, 1 × 3 ... 1 × 6, 1 × 3],
            proposal: 1 × 12
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-+
            |A|
            |A|
            |A|
            | |
            |B|
            |B|
            |B|
            |B|
            | |
            |C|
            |C|
            |C|
            +-+
            """
        }
        #expect(result.reportedSize == (1 × 12))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 3)
            placed(at: 0, 4, size: 1 × 4)
            placed(at: 0, 9, size: 1 × 3)
        }
    }

    @Test func HFlow_distributedOversizedSingleItem_reportsNaturalItemSize() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: [10 × 3],
            proposal: 5 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAAAAAAAAA|
            |AAAAAAAAAA|
            |AAAAAAAAAA|
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 10 × 3)
        }
    }

    @Test func VFlow_distributedOversizedSingleItem_reportsNaturalItemSize() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: [3 × 10],
            proposal: 5 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            |AAA|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 10)
        }
    }

    @Test func HFlow_distributedEvenly_balancesRowsWithExactPlacements() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true),
            subviews: repeated(1 × 1, times: 13),
            proposal: 11 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---------+
            |A B C D E|
            |F G H I  |
            |J K L M  |
            +---------+
            """
        }
        #expect(result.reportedSize == (9 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 1)
            placed(at: 2, 0, size: 1 × 1)
            placed(at: 4, 0, size: 1 × 1)
            placed(at: 6, 0, size: 1 × 1)
            placed(at: 8, 0, size: 1 × 1)
            placed(at: 0, 1, size: 1 × 1)
            placed(at: 2, 1, size: 1 × 1)
            placed(at: 4, 1, size: 1 × 1)
            placed(at: 6, 1, size: 1 × 1)
            placed(at: 0, 2, size: 1 × 1)
            placed(at: 2, 2, size: 1 × 1)
            placed(at: 4, 2, size: 1 × 1)
            placed(at: 6, 2, size: 1 × 1)
        }
    }

    @Test func VFlow_distributedEvenly_balancesColumnsWithExactPlacements() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true),
            subviews: repeated(1 × 1, times: 7),
            proposal: 3 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |ADF|
            |   |
            |BEG|
            |   |
            |C  |
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 5))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 1)
            placed(at: 0, 2, size: 1 × 1)
            placed(at: 0, 4, size: 1 × 1)
            placed(at: 1, 0, size: 1 × 1)
            placed(at: 1, 2, size: 1 × 1)
            placed(at: 2, 0, size: 1 × 1)
            placed(at: 2, 2, size: 1 × 1)
        }
    }
}
