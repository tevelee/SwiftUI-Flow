import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowTextBaselineRequirementTests {
    @Test func HFlow_wrappingText_reflowsIntoProposedWidth() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [WrappingText(size: 6 × 1), 1 × 1, 1 × 1, 1 × 1],
            proposal: 5 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            |AAAAA|
            |AAAAA|
            |B C D|
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 3))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 5 × 2)
            placed(at: 0, 2, size: 1 × 1)
            placed(at: 2, 2, size: 1 × 1)
            placed(at: 4, 2, size: 1 × 1)
        }
    }

    @Test func VFlow_wrappingText_reflowsIntoProposedHeight() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [WrappingText(size: 1 × 6), 1 × 1, 1 × 1, 1 × 1],
            proposal: 3 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAB|
            |AA |
            |AAC|
            |AA |
            |AAD|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 5))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 2 × 5)
            placed(at: 2, 0, size: 1 × 1)
            placed(at: 2, 2, size: 1 × 1)
            placed(at: 2, 4, size: 1 × 1)
        }
    }

    @Test func HFlow_firstTextBaseline_alignsExactPlacements() {
        let small = TestSubview(size: 3 × 4)
        small.firstBaseline = 3
        let large = TestSubview(size: 3 × 10)
        large.firstBaseline = 8

        let result = FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .firstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [small, large],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------+
            |   BBB|
            |   BBB|
            |   BBB|
            |   BBB|
            |   BBB|
            |AAABBB|
            |AAABBB|
            |AAABBB|
            |AAABBB|
            |   BBB|
            +------+
            """
        }
        #expect(result.reportedSize == (6 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 5, size: 3 × 4)
            placed(at: 3, 0, size: 3 × 10)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 6×10
            placements:
            A[0]: origin: 0×5, size: 3×4
            B[1]: origin: 3×0, size: 3×10
            """
        }
    }

    @Test func HFlow_firstTextBaseline_reservesDeepestDescentBelowCommonBaseline() {
        let shallowDescent = TestSubview(size: 3 × 6)
        shallowDescent.firstBaseline = 5
        let deepDescent = TestSubview(size: 3 × 6)
        deepDescent.firstBaseline = 2

        let result = FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .firstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [shallowDescent, deepDescent],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------+
            |AAA   |
            |AAA   |
            |AAA   |
            |AAABBB|
            |AAABBB|
            |AAABBB|
            |   BBB|
            |   BBB|
            |   BBB|
            +------+
            """
        }
        #expect(result.reportedSize == (6 × 9))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 6)
            placed(at: 3, 3, size: 3 × 6)
        }
        assertLayoutTranscript(result) {
            """
            reportedSize: 6×9
            placements:
            A[0]: origin: 0×0, size: 3×6
            B[1]: origin: 3×3, size: 3×6
            """
        }
    }

    @Test func HFlow_lastTextBaseline_alignsExactPlacements() {
        let small = TestSubview(size: 3 × 4)
        small.lastBaseline = 3
        let large = TestSubview(size: 3 × 10)
        large.lastBaseline = 8

        let result = FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .lastTextBaseline, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [small, large],
            proposal: 100 × 100
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------+
            |   BBB|
            |   BBB|
            |   BBB|
            |   BBB|
            |   BBB|
            |AAABBB|
            |AAABBB|
            |AAABBB|
            |AAABBB|
            |   BBB|
            +------+
            """
        }
        #expect(result.reportedSize == (6 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 5, size: 3 × 4)
            placed(at: 3, 0, size: 3 × 10)
        }
    }
}
