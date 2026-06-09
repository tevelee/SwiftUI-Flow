import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowSizingRequirementTests {
    @Test func HFlow_singleElement_reportsElementSize() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 10, verticalSpacing: 20),
            subviews: [50 × 50],
            proposal: 100 × 100
        )
        .assertExpectedLayout(
            size: 50 × 50,
            placements: [
                .init(position: (0, 0), size: 50 × 50)
            ]
        )
    }

    @Test func VFlow_singleElement_reportsElementSize() {
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 20, verticalSpacing: 10),
            subviews: [50 × 50],
            proposal: 100 × 100
        )
        .assertExpectedLayout(
            size: 50 × 50,
            placements: [
                .init(position: (0, 0), size: 50 × 50)
            ]
        )
    }

    @Test func HFlow_multipleElements_wrapIntoRowsAndReportNaturalSize() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 10, verticalSpacing: 20),
            subviews: repeated(50 × 50, times: 3),
            proposal: 130 × 130
        )
        .assertExpectedLayout(
            size: 110 × 120,
            placements: [
                .init(position: (0, 0), size: 50 × 50),
                .init(position: (60, 0), size: 50 × 50),
                .init(position: (0, 70), size: 50 × 50),
            ]
        )
    }

    @Test func VFlow_multipleElements_wrapIntoColumnsAndReportNaturalSize() {
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 20, verticalSpacing: 10),
            subviews: repeated(50 × 50, times: 3),
            proposal: 130 × 130
        )
        .assertExpectedLayout(
            size: 120 × 110,
            placements: [
                .init(position: (0, 0), size: 50 × 50),
                .init(position: (0, 60), size: 50 × 50),
                .init(position: (70, 0), size: 50 × 50),
            ]
        )
    }

    @Test func HFlow_justifiedSize_fillsProposedWidth() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [50 × 50, 50 × 50],
            proposal: 1000 × 1000
        )
        .assertExpectedLayout(
            size: 1000 × 50,
            placements: [
                .init(position: (0, 0), size: 50 × 50),
                .init(position: (950, 0), size: 50 × 50),
            ]
        )
    }

    @Test func VFlow_justifiedSize_fillsProposedHeight() {
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [50 × 50, 50 × 50],
            proposal: 1000 × 1000
        )
        .assertExpectedLayout(
            size: 50 × 1000,
            placements: [
                .init(position: (0, 0), size: 50 × 50),
                .init(position: (0, 950), size: 50 × 50),
            ]
        )
    }

    @Test func HFlow_emptySubviews_reportsZeroSize() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [],
            proposal: 100 × 100
        )
        .assertExpectedLayout(size: .zero, placements: [])
    }

    @Test func HFlow_nilLineSpacing_usesNaturalViewSpacingBetweenRows() {
        // verticalSpacing: nil exercises the adjacentPairs() path in updateLineSpacings:
        // each row's leading space is computed from its direct predecessor via
        // ViewSpacing.distance(to:along:). Default ViewSpacing() gives 8pt natural spacing.
        FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .leading, horizontalSpacing: 1, verticalSpacing: nil),
            subviews: [3 × 1, 3 × 1, 3 × 1],
            proposal: 8 × 100
        )
        .assertExpectedLayout(
            size: 7 × 10,
            placements: [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (4, 0), size: 3 × 1),
                .init(position: (0, 9), size: 3 × 1),
            ]
        )
    }

    @Test func HFlow_nonZeroBoundsOrigin_offsetsAllPlacements() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 0),
            subviews: [3 × 1, 3 × 1],
            proposal: 10 × 1,
            bounds: CGRect(origin: CGPoint(x: 5, y: 3), size: CGSize(width: 10, height: 1))
        )
        .assertExpectedLayout(
            size: 7 × 1,
            placements: [
                .init(position: (5, 3), size: 3 × 1),
                .init(position: (9, 3), size: 3 × 1),
            ]
        )
    }

    @Test func HFlow_zeroSizeSubviews_reportZeroSizeAndFinitePlacements() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [TestSubview(size: .zero), TestSubview(size: .zero)],
            proposal: 100 × 100
        )
        .assertExpectedLayout(
            size: .zero,
            placements: [
                .init(position: (0, 0), size: .zero),
                .init(position: (0, 0), size: .zero),
            ]
        )
    }
}
