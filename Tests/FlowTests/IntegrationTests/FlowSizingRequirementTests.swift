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
        .assertExpectedLayout(size: 50 × 50) {
            placed(at: 0, 0, size: 50 × 50)
        }
    }

    @Test func VFlow_singleElement_reportsElementSize() {
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 20, verticalSpacing: 10),
            subviews: [50 × 50],
            proposal: 100 × 100
        )
        .assertExpectedLayout(size: 50 × 50) {
            placed(at: 0, 0, size: 50 × 50)
        }
    }

    @Test func HFlow_multipleElements_wrapIntoRowsAndReportNaturalSize() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 10, verticalSpacing: 20),
            subviews: repeated(50 × 50, times: 3),
            proposal: 130 × 130
        )
        .assertExpectedLayout(size: 110 × 120) {
            placed(at: 0, 0, size: 50 × 50)
            placed(at: 60, 0, size: 50 × 50)
            placed(at: 0, 70, size: 50 × 50)
        }
    }

    @Test func VFlow_multipleElements_wrapIntoColumnsAndReportNaturalSize() {
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 20, verticalSpacing: 10),
            subviews: repeated(50 × 50, times: 3),
            proposal: 130 × 130
        )
        .assertExpectedLayout(size: 120 × 110) {
            placed(at: 0, 0, size: 50 × 50)
            placed(at: 0, 60, size: 50 × 50)
            placed(at: 70, 0, size: 50 × 50)
        }
    }

    @Test func HFlow_justifiedSize_fillsProposedWidth() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [50 × 50, 50 × 50],
            proposal: 1000 × 1000
        )
        .assertExpectedLayout(size: 1000 × 50) {
            placed(at: 0, 0, size: 50 × 50)
            placed(at: 950, 0, size: 50 × 50)
        }
    }

    @Test func VFlow_justifiedSize_fillsProposedHeight() {
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [50 × 50, 50 × 50],
            proposal: 1000 × 1000
        )
        .assertExpectedLayout(size: 50 × 1000) {
            placed(at: 0, 0, size: 50 × 50)
            placed(at: 0, 950, size: 50 × 50)
        }
    }

    @Test func HFlow_emptySubviews_reportsZeroSize() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1),
            subviews: [],
            proposal: 100 × 100
        )
        .assertExpectedLayout(size: .zero) {}
    }

    @Test func HFlow_zeroSizeSubviews_reportZeroSizeAndFinitePlacements() {
        FlowLayoutScenario(
            layout: .horizontal(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [TestSubview(size: .zero), TestSubview(size: .zero)],
            proposal: 100 × 100
        )
        .assertExpectedLayout(size: .zero) {
            placed(at: 0, 0, size: .zero)
            placed(at: 0, 0, size: .zero)
        }
    }
}
