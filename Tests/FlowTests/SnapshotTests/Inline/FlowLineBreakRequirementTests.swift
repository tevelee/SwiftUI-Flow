import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowLineBreakRequirementTests {
    @Test func HFlow_lineBreakMarker_forcesNewRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, testLineBreakSubview(), 3 × 1],
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            |CCC|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (0, 1.5), size: .zero),
                .init(position: (0, 1), size: 3 × 1),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 3×2
            placements:
            A[0]: origin: 0×0, size: 3×1
            B[1]: origin: 0×1.5, size: 0×0
            C[2]: origin: 0×1, size: 3×1
            """
        }
    }

    @Test func HFlow_lineBreakAtStart_doesNotCreateEmptyVisibleRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [testLineBreakSubview(), 3 × 1],
            proposal: 10 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |BBB|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 1))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0.5), size: .zero),
                .init(position: (0, 0), size: 3 × 1),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 3×1
            placements:
            A[0]: origin: 0×0.5, size: 0×0
            B[1]: origin: 0×0, size: 3×1
            """
        }
    }

    @Test func HFlow_lineBreakAtEnd_doesNotIncreaseVisibleSize() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, testLineBreakSubview()],
            proposal: 10 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 1))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (0, 1), size: .zero),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 3×1
            placements:
            A[0]: origin: 0×0, size: 3×1
            B[1]: origin: 0×1, size: 0×0
            """
        }
    }

    @Test func HFlow_multipleConsecutiveLineBreaks_collapseEmptyRows() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, testLineBreakSubview(), testLineBreakSubview(), 3 × 1],
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            |DDD|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (0, 1), size: .zero),
                .init(position: (0, 1.5), size: .zero),
                .init(position: (0, 1), size: 3 × 1),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 3×2
            placements:
            A[0]: origin: 0×0, size: 3×1
            B[1]: origin: 0×1, size: 0×0
            C[2]: origin: 0×1.5, size: 0×0
            D[3]: origin: 0×1, size: 3×1
            """
        }
    }

    @Test func HFlow_startInNewLine_forcesNewRowWhenNotFirstItem() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, 3 × 1, testNewLineSubview(3 × 1)],
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-------+
            |AAA BBB|
            |CCC    |
            +-------+
            """
        }
        #expect(result.reportedSize == (7 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (4, 0), size: 3 × 1),
                .init(position: (0, 1), size: 3 × 1),
            ]
        )
    }

    @Test func HFlow_startInNewLineOnFirstItem_doesNotCreateEmptyRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [testNewLineSubview(3 × 1), 3 × 1],
            proposal: 10 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-------+
            |AAA BBB|
            +-------+
            """
        }
        #expect(result.reportedSize == (7 × 1))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (4, 0), size: 3 × 1),
            ]
        )
    }

    @Test func HFlow_startInNewLineOnEveryItem_placesEachItemInOwnRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: (0 ..< 3).map { _ in testNewLineSubview(3 × 1) },
            proposal: 10 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            |BBB|
            |CCC|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (0, 1), size: 3 × 1),
                .init(position: (0, 2), size: 3 × 1),
            ]
        )
    }

    @Test func VFlow_lineBreakMarker_forcesNewColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [1 × 3, testLineBreakSubview(), 1 × 3],
            proposal: 2 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AC|
            |AC|
            |AC|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 3),
                .init(position: (1.5, 0), size: .zero),
                .init(position: (1, 0), size: 1 × 3),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 2×3
            placements:
            A[0]: origin: 0×0, size: 1×3
            B[1]: origin: 1.5×0, size: 0×0
            C[2]: origin: 1×0, size: 1×3
            """
        }
    }

    @Test func VFlow_lineBreakAtStart_doesNotCreateEmptyVisibleColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [testLineBreakSubview(), 1 × 3],
            proposal: 1 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-+
            |B|
            |B|
            |B|
            +-+
            """
        }
        #expect(result.reportedSize == (1 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0.5, 0), size: .zero),
                .init(position: (0, 0), size: 1 × 3),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 1×3
            placements:
            A[0]: origin: 0.5×0, size: 0×0
            B[1]: origin: 0×0, size: 1×3
            """
        }
    }

    @Test func VFlow_lineBreakAtEnd_doesNotIncreaseVisibleSize() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [1 × 3, testLineBreakSubview()],
            proposal: 1 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-+
            |A|
            |A|
            |A|
            +-+
            """
        }
        #expect(result.reportedSize == (1 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 3),
                .init(position: (1, 0), size: .zero),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 1×3
            placements:
            A[0]: origin: 0×0, size: 1×3
            B[1]: origin: 1×0, size: 0×0
            """
        }
    }

    @Test func VFlow_multipleConsecutiveLineBreaks_collapseEmptyColumns() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [1 × 3, testLineBreakSubview(), testLineBreakSubview(), 1 × 3],
            proposal: 2 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AD|
            |AD|
            |AD|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 3),
                .init(position: (1, 0), size: .zero),
                .init(position: (1.5, 0), size: .zero),
                .init(position: (1, 0), size: 1 × 3),
            ]
        )
        assertLayoutTranscript(result) {
            """
            reportedSize: 2×3
            placements:
            A[0]: origin: 0×0, size: 1×3
            B[1]: origin: 1×0, size: 0×0
            C[2]: origin: 1.5×0, size: 0×0
            D[3]: origin: 1×0, size: 1×3
            """
        }
    }

    @Test func VFlow_startInNewLine_forcesNewColumnWhenNotFirstItem() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [1 × 3, 1 × 3, testNewLineSubview(1 × 3)],
            proposal: 2 × 7
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AC|
            |AC|
            |AC|
            |  |
            |B |
            |B |
            |B |
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 7))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 3),
                .init(position: (0, 4), size: 1 × 3),
                .init(position: (1, 0), size: 1 × 3),
            ]
        )
    }
}
