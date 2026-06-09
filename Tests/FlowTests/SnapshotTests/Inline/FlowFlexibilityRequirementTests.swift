import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowFlexibilityRequirementTests {
    @Test func HFlow_naturalFlexItems_shareRemainingWidth() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [1 × 1 ... 6 × 1, 1 × 1 ... 6 × 1],
            proposal: 6 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------+
            |AAABBB|
            +------+
            """
        }
        #expect(result.reportedSize == (6 × 1))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (3, 0), size: 3 × 1),
            ]
        )
    }

    @Test func HFlow_minimumFlexItem_doesNotConsumeRemainingWidth() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [
                1 × 1 ... 5 × 1,
                (1 × 1 ... 5 × 1).flexibility(.minimum),
            ],
            proposal: 7 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-------+
            |AAAAA B|
            +-------+
            """
        }
        #expect(result.reportedSize == (7 × 1))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 5 × 1),
                .init(position: (6, 0), size: 1 × 1),
            ]
        )
    }

    @Test func HFlow_maximumFlexItem_movesToOwnRowWhenItCannotFullyExpandInCurrentRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [
                3 × 1,
                (1 × 1 ... 10 × 1).flexibility(.maximum),
                3 × 1,
            ],
            proposal: 10 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAA       |
            |BBBBBBBBBB|
            |CCC       |
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (0, 1), size: 10 × 1),
                .init(position: (0, 2), size: 3 × 1),
            ]
        )
    }

    @Test func HFlow_multipleMaximumFlexItems_eachTakeTheirOwnRow() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [
                (1 × 1 ... 10 × 1).flexibility(.maximum),
                (1 × 1 ... 10 × 1).flexibility(.maximum),
            ],
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAAAAAAAAA|
            |BBBBBBBBBB|
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 10 × 1),
                .init(position: (0, 1), size: 10 × 1),
            ]
        )
    }

    @Test func HFlow_higherPriorityFlexItem_consumesRemainingWidthFirst() {
        let lowerPriority = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 5 × 1)
        let higherPriority = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 5 × 1)
        higherPriority.priority = 2

        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [lowerPriority, higherPriority],
            proposal: 7 × 1
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-------+
            |A BBBBB|
            +-------+
            """
        }
        #expect(result.reportedSize == (7 × 1))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (2, 0), size: 5 × 1),
            ]
        )
    }

    @Test func VFlow_higherPriorityFlexItem_consumesRemainingHeightFirst() {
        let lowerPriority = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 1 × 5)
        let higherPriority = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 1 × 5)
        higherPriority.priority = 2

        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [lowerPriority, higherPriority],
            proposal: 1 × 7
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-+
            |A|
            | |
            |B|
            |B|
            |B|
            |B|
            |B|
            +-+
            """
        }
        #expect(result.reportedSize == (1 × 7))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (0, 2), size: 1 × 5),
            ]
        )
    }

    @Test func VFlow_naturalFlexItems_shareRemainingHeight() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [1 × 1 ... 1 × 5, 1 × 1 ... 1 × 5],
            proposal: 1 × 6
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-+
            |A|
            |A|
            |A|
            |B|
            |B|
            |B|
            +-+
            """
        }
        #expect(result.reportedSize == (1 × 6))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 3),
                .init(position: (0, 3), size: 1 × 3),
            ]
        )
    }

    @Test func VFlow_maximumFlexItem_movesToOwnColumnWhenItCannotFullyExpandInCurrentColumn() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [
                1 × 1,
                (1 × 1 ... 1 × 8).flexibility(.maximum),
                1 × 1,
            ],
            proposal: 3 × 8
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |ABC|
            | B |
            | B |
            | B |
            | B |
            | B |
            | B |
            | B |
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 8))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (1, 0), size: 1 × 8),
                .init(position: (2, 0), size: 1 × 1),
            ]
        )
    }

    @Test func VFlow_minimumFlexItem_doesNotConsumeRemainingHeight() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
            subviews: [
                1 × 1,
                1 × 1,
                (1 × 1 ... 1 × 5).flexibility(.minimum),
                1 × 1,
                1 × 1,
            ],
            proposal: 2 × 8
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AE|
            |  |
            |B |
            |  |
            |C |
            |  |
            |D |
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 7))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (0, 2), size: 1 × 1),
                .init(position: (0, 4), size: 1 × 1),
                .init(position: (0, 6), size: 1 × 1),
                .init(position: (1, 0), size: 1 × 1),
            ]
        )
    }

    @Test func VFlow_infiniteMaxWidthItem_fillsColumnNaturalWidth() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [5 × 1, 1 × 1 ... inf × 1],
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            |AAAAA|
            |BBBBB|
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 5 × 1),
                .init(position: (0, 1), size: 5 × 1),
            ]
        )
    }

    @Test func VFlow_finiteMaxWidthItem_canExpandBeyondColumnNaturalWidth() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalAlignment: .leading, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [5 × 1, 1 × 1 ... 10 × 1],
            proposal: 10 × 2
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----------+
            |AAAAA     |
            |BBBBBBBBBB|
            +----------+
            """
        }
        #expect(result.reportedSize == (10 × 2))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 5 × 1),
                .init(position: (0, 1), size: 10 × 1),
            ]
        )
    }

    @Test func HFlow_infiniteMaxHeightItem_fillsRowNaturalHeight() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [1 × 5, 1 × 1 ... 1 × inf],
            proposal: 2 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AB|
            |AB|
            |AB|
            |AB|
            |AB|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 5))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 5),
                .init(position: (1, 0), size: 1 × 5),
            ]
        )
    }

    @Test func HFlow_finiteMaxHeightItem_canExpandBeyondRowNaturalHeight() {
        let result = FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [1 × 5, 1 × 1 ... 1 × 10],
            proposal: 2 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +--+
            |AB|
            |AB|
            |AB|
            |AB|
            |AB|
            | B|
            | B|
            | B|
            | B|
            | B|
            +--+
            """
        }
        #expect(result.reportedSize == (2 × 10))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 5),
                .init(position: (1, 0), size: 1 × 10),
            ]
        )
    }
}
