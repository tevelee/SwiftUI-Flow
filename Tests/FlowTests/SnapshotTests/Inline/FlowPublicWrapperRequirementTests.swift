import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowPublicWrapperRequirementTests {
    @Test func HFlowLayout_convenienceInitializer_mapsItemRowSpacingAndJustification() {
        let result = FlowLayoutScenario(
            layout: HFlowLayout(alignment: .top, itemSpacing: 1, rowSpacing: 2, justified: true).layout,
            subviews: repeated(1 × 1, times: 4),
            proposal: 4 × 4
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----+
            |A  B|
            |    |
            |    |
            |C  D|
            +----+
            """
        }
        #expect(result.reportedSize == (4 × 4))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (3, 0), size: 1 × 1),
                .init(position: (0, 3), size: 1 × 1),
                .init(position: (3, 3), size: 1 × 1),
            ]
        )
    }

    @Test func VFlowLayout_convenienceInitializer_mapsItemColumnSpacingAndJustification() {
        let result = FlowLayoutScenario(
            layout: VFlowLayout(alignment: .leading, itemSpacing: 1, columnSpacing: 2, justified: true).layout,
            subviews: repeated(1 × 1, times: 4),
            proposal: 4 × 4
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----+
            |A  C|
            |    |
            |    |
            |B  D|
            +----+
            """
        }
        #expect(result.reportedSize == (4 × 4))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (0, 3), size: 1 × 1),
                .init(position: (3, 0), size: 1 × 1),
                .init(position: (3, 3), size: 1 × 1),
            ]
        )
    }

    @Test func HFlowLayout_fullInitializer_mapsHorizontalAlignment() {
        let result = FlowLayoutScenario(
            layout: HFlowLayout(
                horizontalAlignment: .center,
                verticalAlignment: .top,
                horizontalSpacing: 1,
                verticalSpacing: 1
            )
            .layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +-----+
            |AA BB|
            |     |
            | CC  |
            +-----+
            """
        }
        #expect(result.reportedSize == (5 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (3, 0), size: 2 × 1),
                .init(position: (1.5, 2), size: 2 × 1),
            ]
        )
    }

    @Test func VFlowLayout_fullInitializer_mapsVerticalAlignment() {
        let result = FlowLayoutScenario(
            layout: VFlowLayout(
                horizontalAlignment: .leading,
                verticalAlignment: .center,
                horizontalSpacing: 1,
                verticalSpacing: 1
            )
            .layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |A  |
            |A C|
            |  C|
            |B  |
            |B  |
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 5))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 3), size: 1 × 2),
                .init(position: (2, 1.5), size: 1 × 2),
            ]
        )
    }

    @MainActor
    @Test func HFlow_emptyViewLayoutInitializer_mapsSpacingShortcut() {
        let result = FlowLayoutScenario(
            layout: HFlow<EmptyView>(alignment: .top, spacing: 1, justified: true).layout.layout,
            subviews: repeated(1 × 1, times: 4),
            proposal: 4 × 3
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +----+
            |A  B|
            |    |
            |C  D|
            +----+
            """
        }
        #expect(result.reportedSize == (4 × 3))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (3, 0), size: 1 × 1),
                .init(position: (0, 2), size: 1 × 1),
                .init(position: (3, 2), size: 1 × 1),
            ]
        )
    }

    @MainActor
    @Test func VFlow_emptyViewLayoutInitializer_mapsSpacingShortcut() {
        let result = FlowLayoutScenario(
            layout: VFlow<EmptyView>(alignment: .leading, spacing: 1, justified: true).layout.layout,
            subviews: repeated(1 × 1, times: 4),
            proposal: 3 × 4
        )
        .layoutThatFits()

        assertLayoutRendering(result) {
            """
            +---+
            |A C|
            |   |
            |   |
            |B D|
            +---+
            """
        }
        #expect(result.reportedSize == (3 × 4))
        expectPlacements(
            result.subviews,
            [
                .init(position: (0, 0), size: 1 × 1),
                .init(position: (0, 3), size: 1 × 1),
                .init(position: (2, 0), size: 1 × 1),
                .init(position: (2, 3), size: 1 × 1),
            ]
        )
    }

}
