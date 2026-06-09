import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowPublicAPIRequirementTests {
    // MARK: - HFlowLayout initializers

    @Test func HFlowLayout_convenienceInit_placesItemsInRowsWithSeparateItemAndRowSpacing() {
        FlowLayoutScenario(
            layout: HFlowLayout(alignment: .top, itemSpacing: 1, rowSpacing: 2).layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(
            size: 5 × 4,
            placements: [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (3, 0), size: 2 × 1),
                .init(position: (0, 3), size: 2 × 1),
            ]
        )
    }

    @Test func HFlowLayout_fullInit_placesItemsUsingHorizontalAndVerticalAlignment() {
        FlowLayoutScenario(
            layout: HFlowLayout(
                horizontalAlignment: .trailing,
                verticalAlignment: .top,
                horizontalSpacing: 1,
                verticalSpacing: 1
            ).layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(
            size: 5 × 3,
            placements: [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (3, 0), size: 2 × 1),
                .init(position: (3, 2), size: 2 × 1),
            ]
        )
    }

    // MARK: - VFlowLayout initializers

    @Test func VFlowLayout_convenienceInit_placesItemsInColumnsWithSeparateItemAndColumnSpacing() {
        FlowLayoutScenario(
            layout: VFlowLayout(alignment: .leading, itemSpacing: 1, columnSpacing: 2).layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(
            size: 4 × 5,
            placements: [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 3), size: 1 × 2),
                .init(position: (3, 0), size: 1 × 2),
            ]
        )
    }

    @Test func VFlowLayout_fullInit_placesItemsUsingHorizontalAndVerticalAlignment() {
        FlowLayoutScenario(
            layout: VFlowLayout(
                horizontalAlignment: .leading,
                verticalAlignment: .bottom,
                horizontalSpacing: 1,
                verticalSpacing: 1
            ).layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(
            size: 3 × 5,
            placements: [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 3), size: 1 × 2),
                .init(position: (2, 3), size: 1 × 2),
            ]
        )
    }

    // MARK: - HFlow / VFlow Layout-conformance initializers

    @MainActor
    @Test func HFlow_itemRowSpacingInit_placesItemsInRowsWithSeparateSpacings() {
        FlowLayoutScenario(
            layout: HFlow<EmptyView>(alignment: .top, itemSpacing: 1, rowSpacing: 2).layout.layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(
            size: 5 × 4,
            placements: [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (3, 0), size: 2 × 1),
                .init(position: (0, 3), size: 2 × 1),
            ]
        )
    }

    @MainActor
    @Test func VFlow_itemColumnSpacingInit_placesItemsInColumnsWithSeparateSpacings() {
        FlowLayoutScenario(
            layout: VFlow<EmptyView>(alignment: .leading, itemSpacing: 1, columnSpacing: 2).layout.layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(
            size: 4 × 5,
            placements: [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 3), size: 1 × 2),
                .init(position: (3, 0), size: 1 × 2),
            ]
        )
    }

    @MainActor
    @Test func HFlow_spacingShortcutInit_placesItemsInRows() {
        FlowLayoutScenario(
            layout: HFlow<EmptyView>(alignment: .top, spacing: 1).layout.layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(
            size: 5 × 3,
            placements: [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (3, 0), size: 2 × 1),
                .init(position: (0, 2), size: 2 × 1),
            ]
        )
    }

    @MainActor
    @Test func VFlow_spacingShortcutInit_placesItemsInColumns() {
        FlowLayoutScenario(
            layout: VFlow<EmptyView>(alignment: .leading, spacing: 1).layout.layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(
            size: 3 × 5,
            placements: [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 3), size: 1 × 2),
                .init(position: (2, 0), size: 1 × 2),
            ]
        )
    }

    @MainActor
    @Test func HFlow_fullInit_placesItemsUsingHorizontalAndVerticalAlignment() {
        FlowLayoutScenario(
            layout: HFlow<EmptyView>(
                horizontalAlignment: .trailing,
                verticalAlignment: .top,
                horizontalSpacing: 1,
                verticalSpacing: 1
            ).layout.layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(
            size: 5 × 3,
            placements: [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (3, 0), size: 2 × 1),
                .init(position: (3, 2), size: 2 × 1),
            ]
        )
    }

    @MainActor
    @Test func VFlow_fullInit_placesItemsUsingHorizontalAndVerticalAlignment() {
        FlowLayoutScenario(
            layout: VFlow<EmptyView>(
                horizontalAlignment: .leading,
                verticalAlignment: .bottom,
                horizontalSpacing: 1,
                verticalSpacing: 1
            ).layout.layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(
            size: 3 × 5,
            placements: [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 3), size: 1 × 2),
                .init(position: (2, 3), size: 1 × 2),
            ]
        )
    }

    // MARK: - Justified and distributed

    @Test func HFlowLayout_convenienceInit_withJustified_stretchesRowToFillWidth() {
        // 3 items × 2pt with 1pt natural gaps → natural width 8. Justified in 10pt stretches gaps to 3pt each.
        FlowLayoutScenario(
            layout: HFlowLayout(alignment: .top, itemSpacing: 1, rowSpacing: 0, justified: true).layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 10 × 10
        )
        .assertExpectedLayout(
            size: 10 × 1,
            placements: [
                .init(position: (0, 0), size: 2 × 1),
                .init(position: (4, 0), size: 2 × 1),
                .init(position: (8, 0), size: 2 × 1),
            ]
        )
    }

    @Test func VFlowLayout_convenienceInit_withJustified_stretchesColumnToFillHeight() {
        // 3 items × 2pt with 1pt natural gaps → natural height 8. Justified in 10pt stretches gaps to 3pt each.
        FlowLayoutScenario(
            layout: VFlowLayout(alignment: .leading, itemSpacing: 1, columnSpacing: 0, justified: true).layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 10
        )
        .assertExpectedLayout(
            size: 1 × 10,
            placements: [
                .init(position: (0, 0), size: 1 × 2),
                .init(position: (0, 4), size: 1 × 2),
                .init(position: (0, 8), size: 1 × 2),
            ]
        )
    }

    @Test func HFlowLayout_convenienceInit_withDistributeItemsEvenly_balancesLines() {
        // 4 items × 10pt, 10pt spacing, 50pt container.
        // Greedy: row1=[0,1,2] (40pt), row2=[3] (10pt) → size 40×2.
        // Knuth-Plass: row1=[0,1] (30pt), row2=[2,3] (30pt) → size 30×2.
        FlowLayoutScenario(
            layout: HFlowLayout(alignment: .top, itemSpacing: 10, rowSpacing: 0, distributeItemsEvenly: true).layout,
            subviews: [10 × 1, 10 × 1, 10 × 1, 10 × 1],
            proposal: 50 × 10
        )
        .assertExpectedLayout(
            size: 30 × 2,
            placements: [
                .init(position: (0, 0), size: 10 × 1),
                .init(position: (20, 0), size: 10 × 1),
                .init(position: (0, 1), size: 10 × 1),
                .init(position: (20, 1), size: 10 × 1),
            ]
        )
    }

    @Test func VFlowLayout_convenienceInit_withDistributeItemsEvenly_balancesColumns() {
        // 4 items × 10pt, 10pt spacing, 50pt container.
        // Knuth-Plass: col1=[0,1] (30pt), col2=[2,3] (30pt) → size 2×30.
        FlowLayoutScenario(
            layout: VFlowLayout(alignment: .leading, itemSpacing: 10, columnSpacing: 0, distributeItemsEvenly: true).layout,
            subviews: [1 × 10, 1 × 10, 1 × 10, 1 × 10],
            proposal: 10 × 50
        )
        .assertExpectedLayout(
            size: 2 × 30,
            placements: [
                .init(position: (0, 0), size: 1 × 10),
                .init(position: (0, 20), size: 1 × 10),
                .init(position: (1, 0), size: 1 × 10),
                .init(position: (1, 20), size: 1 × 10),
            ]
        )
    }

    // MARK: - Stack orientation

    @Test func publicLayouts_exposeCorrectSwiftUIStackOrientation() {
        #expect(HFlowLayout.layoutProperties.stackOrientation == .horizontal)
        #expect(HFlow<EmptyView>.layoutProperties.stackOrientation == .horizontal)
        #expect(VFlowLayout.layoutProperties.stackOrientation == .vertical)
        #expect(VFlow<EmptyView>.layoutProperties.stackOrientation == .vertical)
    }
}
