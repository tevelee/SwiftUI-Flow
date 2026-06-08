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
        .assertExpectedLayout(size: 5 × 4) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 0, 3, size: 2 × 1)
        }
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
        .assertExpectedLayout(size: 5 × 3) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 3, 2, size: 2 × 1)
        }
    }

    // MARK: - VFlowLayout initializers

    @Test func VFlowLayout_convenienceInit_placesItemsInColumnsWithSeparateItemAndColumnSpacing() {
        FlowLayoutScenario(
            layout: VFlowLayout(alignment: .leading, itemSpacing: 1, columnSpacing: 2).layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(size: 4 × 5) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 3, size: 1 × 2)
            placed(at: 3, 0, size: 1 × 2)
        }
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
        .assertExpectedLayout(size: 3 × 5) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 3, size: 1 × 2)
            placed(at: 2, 3, size: 1 × 2)
        }
    }

    // MARK: - HFlow / VFlow Layout-conformance initializers

    @MainActor
    @Test func HFlow_itemRowSpacingInit_placesItemsInRowsWithSeparateSpacings() {
        FlowLayoutScenario(
            layout: HFlow<EmptyView>(alignment: .top, itemSpacing: 1, rowSpacing: 2).layout.layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(size: 5 × 4) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 0, 3, size: 2 × 1)
        }
    }

    @MainActor
    @Test func VFlow_itemColumnSpacingInit_placesItemsInColumnsWithSeparateSpacings() {
        FlowLayoutScenario(
            layout: VFlow<EmptyView>(alignment: .leading, itemSpacing: 1, columnSpacing: 2).layout.layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(size: 4 × 5) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 3, size: 1 × 2)
            placed(at: 3, 0, size: 1 × 2)
        }
    }

    @MainActor
    @Test func HFlow_spacingShortcutInit_placesItemsInRows() {
        FlowLayoutScenario(
            layout: HFlow<EmptyView>(alignment: .top, spacing: 1).layout.layout,
            subviews: [2 × 1, 2 × 1, 2 × 1],
            proposal: 5 × 10
        )
        .assertExpectedLayout(size: 5 × 3) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 0, 2, size: 2 × 1)
        }
    }

    @MainActor
    @Test func VFlow_spacingShortcutInit_placesItemsInColumns() {
        FlowLayoutScenario(
            layout: VFlow<EmptyView>(alignment: .leading, spacing: 1).layout.layout,
            subviews: [1 × 2, 1 × 2, 1 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(size: 3 × 5) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 3, size: 1 × 2)
            placed(at: 2, 0, size: 1 × 2)
        }
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
        .assertExpectedLayout(size: 5 × 3) {
            placed(at: 0, 0, size: 2 × 1)
            placed(at: 3, 0, size: 2 × 1)
            placed(at: 3, 2, size: 2 × 1)
        }
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
        .assertExpectedLayout(size: 3 × 5) {
            placed(at: 0, 0, size: 1 × 2)
            placed(at: 0, 3, size: 1 × 2)
            placed(at: 2, 3, size: 1 × 2)
        }
    }

    // MARK: - Stack orientation

    @Test func publicLayouts_exposeCorrectSwiftUIStackOrientation() {
        #expect(HFlowLayout.layoutProperties.stackOrientation == .horizontal)
        #expect(HFlow<EmptyView>.layoutProperties.stackOrientation == .horizontal)
        #expect(VFlowLayout.layoutProperties.stackOrientation == .vertical)
        #expect(VFlow<EmptyView>.layoutProperties.stackOrientation == .vertical)
    }
}
