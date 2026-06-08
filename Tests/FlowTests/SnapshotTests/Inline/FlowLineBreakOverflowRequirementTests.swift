import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowLineBreakOverflowRequirementTests {
    @Test func HFlow_singleOversizedItem_reportsNaturalItemSize() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0),
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

    @Test func HFlow_startInNewLineWithMaximumFlex_reportsExactPlacements() {
        let flexItem: TestSubview = (1 × 1 as CGSize) ... (10 × 1 as CGSize)
        flexItem[ShouldStartInNewLineLayoutValueKey.self] = true
        flexItem[FlexibilityLayoutValueKey.self] = .maximum
        let subviews: [TestSubview] = [3 × 1, 3 × 1, flexItem]

        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: subviews,
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAA BBB   |
            |CCCCCCCCCC|
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 2))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 4, 0, size: 3 × 1)
            placed(at: 0, 1, size: 10 × 1)
        }
    }

    @Test func VFlow_startInNewLineWithMaximumFlex_reportsExactPlacements() {
        let flexItem: TestSubview = (1 × 1 as CGSize) ... (1 × 10 as CGSize)
        flexItem[ShouldStartInNewLineLayoutValueKey.self] = true
        flexItem[FlexibilityLayoutValueKey.self] = .maximum
        let subviews: [TestSubview] = [1 × 3, 1 × 3, flexItem]

        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
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
            | C|
            |BC|
            |BC|
            |BC|
            | C|
            | C|
            | C|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 3)
            placed(at: 0, 4, size: 1 × 3)
            placed(at: 1, 0, size: 1 × 10)
        }
    }

    @Test(.tags(.regression)) func HFlow_oversizedItem_doesNotDropNeighbours_reportsExactLayout() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [3 × 1, 10 × 1, 3 × 1, 3 × 1],
            proposal: 5 × 4
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAA       |
            |BBBBBBBBBB|
            |CCC       |
            |DDD       |
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 4))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 3 × 1)
            placed(at: 0, 1, size: 10 × 1)
            placed(at: 0, 2, size: 3 × 1)
            placed(at: 0, 3, size: 3 × 1)
        }
    }

    @Test(.tags(.regression)) func VFlow_oversizedItem_doesNotDropNeighbours_reportsExactLayout() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [1 × 3, 1 × 10, 1 × 3, 1 × 3],
            proposal: 4 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----+
            |ABCD|
            |ABCD|
            |ABCD|
            | B  |
            | B  |
            | B  |
            | B  |
            | B  |
            | B  |
            | B  |
            +----+
            """
        }
        #expect(result.reportedSize == (4 × 10))
        expectPlacements(result.subviews) {
            placed(at: 0, 0, size: 1 × 3)
            placed(at: 1, 0, size: 1 × 10)
            placed(at: 2, 0, size: 1 × 3)
            placed(at: 3, 0, size: 1 × 3)
        }
    }
}
