import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowViewSpacingRequirementTests {
    @Test func HFlow_nilSpacing_usesSubviewSpacingBetweenItemsAndRows() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: nil, verticalSpacing: nil),
            subviews: [3 × 2, 3 × 2, 3 × 2],
            proposal: 20 × 20
        )
        .layoutThatFits()

        #if os(tvOS)
            // tvOS natural ViewSpacing is ~24pt, so items can't fit two per row (3+24+3=30 > 20)
            #expect(result.reportedSize == (3 × 54))
            expectPlacements(
                result.subviews,
                [
                    .init(position: (0, 0), size: 3 × 2),
                    .init(position: (0, 26), size: 3 × 2),
                    .init(position: (0, 52), size: 3 × 2),
                ]
            )
        #else
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA        BBB|
                |AAA        BBB|
                |              |
                |              |
                |              |
                |              |
                |              |
                |              |
                |              |
                |              |
                |CCC           |
                |CCC           |
                +--------------+
                """
            }
            #expect(result.reportedSize == (14 × 12))
            expectPlacements(
                result.subviews,
                [
                    .init(position: (0, 0), size: 3 × 2),
                    .init(position: (11, 0), size: 3 × 2),
                    .init(position: (0, 10), size: 3 × 2),
                ]
            )
        #endif
    }

    @Test func HFlow_nilSpacing_usesZeroSubviewSpacingBetweenItemsAndRows() {
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: nil, verticalSpacing: nil),
            subviews: [zeroSpaced(3 × 2), zeroSpaced(3 × 2), zeroSpaced(3 × 2)],
            proposal: 7 × 20
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +------+
            |AAABBB|
            |AAABBB|
            |CCC   |
            |CCC   |
            +------+
            """
        }
        #expect(result.reportedSize == (6 × 4))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 3 × 2),
                .init(position: (3, 0), size: 3 × 2),
                .init(position: (0, 2), size: 3 × 2),
            ]
        )
    }

    @Test func VFlow_nilSpacing_usesSubviewSpacingBetweenItemsAndColumns() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: nil, verticalSpacing: nil),
            subviews: [2 × 3, 2 × 3, 2 × 3],
            proposal: 20 × 20
        )
        .layoutThatFits()

        #if os(tvOS)
            // tvOS natural ViewSpacing is ~60pt horizontal / ~24pt vertical,
            // so items can't fit two per column (3+24+3=30 > 20); each gets its own column.
            #expect(result.reportedSize == (126 × 3))
            expectPlacements(
                result.subviews,
                [
                    .init(position: (0, 0), size: 2 × 3),
                    .init(position: (62, 0), size: 2 × 3),
                    .init(position: (124, 0), size: 2 × 3),
                ]
            )
        #else
            assertLayoutRendering(result) {
                """
                +------------+
                |AA        CC|
                |AA        CC|
                |AA        CC|
                |            |
                |            |
                |            |
                |            |
                |            |
                |            |
                |            |
                |            |
                |BB          |
                |BB          |
                |BB          |
                +------------+
                """
            }
            #expect(result.reportedSize == (12 × 14))
            expectPlacements(
                result.subviews,
                [
                    .init(position: (0, 0), size: 2 × 3),
                    .init(position: (0, 11), size: 2 × 3),
                    .init(position: (10, 0), size: 2 × 3),
                ]
            )
        #endif
    }

    @Test func VFlow_nilSpacing_usesZeroSubviewSpacingBetweenItemsAndColumns() {
        let result = FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: nil, verticalSpacing: nil),
            subviews: [zeroSpaced(2 × 3), zeroSpaced(2 × 3), zeroSpaced(2 × 3)],
            proposal: 20 × 7
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----+
            |AACC|
            |AACC|
            |AACC|
            |BB  |
            |BB  |
            |BB  |
            +----+
            """
        }
        #expect(result.reportedSize == (4 × 6))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 2 × 3),
                .init(position: (0, 3), size: 2 × 3),
                .init(position: (2, 0), size: 2 × 3),
            ]
        )
    }
}

private func zeroSpaced(_ subview: TestSubview) -> TestSubview {
    subview.spacing = .zero
    return subview
}
