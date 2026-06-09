import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowAlignmentRequirementTests {
    @Test func HFlow_topVerticalAlignment_placesShortItemAtRowTop() {
        assertHFlowVerticalAlignment(.top, shortItemY: 0)
    }

    @Test func HFlow_centerVerticalAlignment_centersShortItemWithinRow() {
        assertHFlowVerticalAlignment(.center, shortItemY: 1)
    }

    @Test func HFlow_bottomVerticalAlignment_placesShortItemAtRowBottom() {
        assertHFlowVerticalAlignment(.bottom, shortItemY: 2)
    }

    @Test func HFlow_leadingHorizontalAlignment_keepsShortFinalRowAtLeadingEdge() {
        assertHFlowHorizontalAlignment(.leading, finalRowX: 0)
    }

    @Test func HFlow_centerHorizontalAlignment_centersShortFinalRow() {
        assertHFlowHorizontalAlignment(.center, finalRowX: 1.5)
    }

    @Test func HFlow_trailingHorizontalAlignment_placesShortFinalRowAtTrailingEdge() {
        assertHFlowHorizontalAlignment(.trailing, finalRowX: 3)
    }

    @Test func VFlow_leadingHorizontalAlignment_placesNarrowItemAtColumnLeadingEdge() {
        assertVFlowHorizontalAlignment(.leading, narrowItemX: 0)
    }

    @Test func VFlow_centerHorizontalAlignment_centersNarrowItemWithinColumn() {
        assertVFlowHorizontalAlignment(.center, narrowItemX: 1)
    }

    @Test func VFlow_trailingHorizontalAlignment_placesNarrowItemAtColumnTrailingEdge() {
        assertVFlowHorizontalAlignment(.trailing, narrowItemX: 2)
    }

    @Test func VFlow_topVerticalAlignment_keepsShortFinalColumnAtTop() {
        assertVFlowVerticalAlignment(.top, finalColumnY: 0)
    }

    @Test func VFlow_centerVerticalAlignment_centersShortFinalColumn() {
        assertVFlowVerticalAlignment(.center, finalColumnY: 1.5)
    }

    @Test func VFlow_bottomVerticalAlignment_placesShortFinalColumnAtBottom() {
        assertVFlowVerticalAlignment(.bottom, finalColumnY: 3)
    }

    @Test func HFlow_firstTextBaseline_alignsItemsToCommonBaseline() {
        let small = TestSubview(size: 3 × 4)
        small.firstBaseline = 3
        let large = TestSubview(size: 3 × 10)
        large.firstBaseline = 8
        // Common baseline = max(3, 8) = 8 from row top.
        // small: ascent gap = 8-3=5 → y=5; large: y=0.
        // Row height = ascent(8) + descent(max(4-3,10-8))=max(1,2)=2 → 10.
        FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .firstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [small, large],
            proposal: 100 × 100
        )
        .assertExpectedLayout(
            size: 6 × 10,
            placements: [
                .init(position: (0, 5), size: 3 × 4),
                .init(position: (3, 0), size: 3 × 10),
            ]
        )
    }

    @Test func HFlow_lastTextBaseline_alignsItemsToCommonBaseline() {
        let small = TestSubview(size: 3 × 4)
        small.lastBaseline = 3
        let large = TestSubview(size: 3 × 10)
        large.lastBaseline = 9
        // Common baseline = max(3, 9) = 9 from row top.
        // small: y=9-3=6; large: y=0.
        // Row height = ascent(9) + descent(max(4-3,10-9))=max(1,1)=1 → 10.
        FlowLayoutScenario(
            layout: .horizontal(verticalAlignment: .lastTextBaseline, horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [small, large],
            proposal: 100 × 100
        )
        .assertExpectedLayout(
            size: 6 × 10,
            placements: [
                .init(position: (0, 6), size: 3 × 4),
                .init(position: (3, 0), size: 3 × 10),
            ]
        )
    }

    @Test(arguments: VFlowCombinedAlignmentCase.allCases)
    func VFlow_combinedHorizontalAndVerticalAlignment_placesItemsAtExpectedOffsets(_ testCase: VFlowCombinedAlignmentCase) {
        FlowLayoutScenario(
            layout: .vertical(
                horizontalAlignment: testCase.horizontalAlignment,
                verticalAlignment: testCase.verticalAlignment,
                horizontalSpacing: 1,
                verticalSpacing: 1
            ),
            subviews: [3 × 2, 1 × 2, 3 × 2],
            proposal: 10 × 5
        )
        .assertExpectedLayout(
            size: 7 × 5,
            placements: [
                .init(position: (0, 0), size: 3 × 2),
                .init(position: (testCase.narrowItemX, 3), size: 1 × 2),
                .init(position: (4, testCase.finalColumnY), size: 3 × 2),
            ]
        )
    }
}

struct VFlowCombinedAlignmentCase: CustomTestStringConvertible {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let narrowItemX: CGFloat
    let finalColumnY: CGFloat

    var testDescription: String {
        "\(horizontalAlignment.testDescription)-\(verticalAlignment.testDescription)"
    }

    static let allCases: [Self] =
        HorizontalAlignment.allCases.flatMap { horizontalAlignment in
            VerticalAlignment.allCases.map { verticalAlignment in
                Self(
                    horizontalAlignment: horizontalAlignment,
                    verticalAlignment: verticalAlignment,
                    narrowItemX: narrowItemX(for: horizontalAlignment),
                    finalColumnY: finalColumnY(for: verticalAlignment)
                )
            }
        }

    private static func narrowItemX(for alignment: HorizontalAlignment) -> CGFloat {
        switch alignment {
            case .leading: 0
            case .center: 1
            case .trailing: 2
            default: 0
        }
    }

    private static func finalColumnY(for alignment: VerticalAlignment) -> CGFloat {
        switch alignment {
            case .top: 0
            case .center: 1.5
            case .bottom: 3
            default: 0
        }
    }
}

private func assertHFlowVerticalAlignment(_ alignment: VerticalAlignment, shortItemY: CGFloat) {
    FlowLayoutScenario(
        layout: .horizontal(verticalAlignment: alignment, horizontalSpacing: 1, verticalSpacing: 0),
        subviews: [3 × 3, 1 × 1],
        proposal: 5 × 3
    )
    .assertExpectedLayout(
        size: 5 × 3,
        placements: [
            .init(position: (0, 0), size: 3 × 3),
            .init(position: (4, shortItemY), size: 1 × 1),
        ]
    )
}

private func assertHFlowHorizontalAlignment(_ alignment: HorizontalAlignment, finalRowX: CGFloat) {
    FlowLayoutScenario(
        layout: .horizontal(
            horizontalAlignment: alignment,
            verticalAlignment: .top,
            horizontalSpacing: 1,
            verticalSpacing: 1
        ),
        subviews: [2 × 1, 2 × 1, 2 × 1],
        proposal: 5 × 10
    )
    .assertExpectedLayout(
        size: 5 × 3,
        placements: [
            .init(position: (0, 0), size: 2 × 1),
            .init(position: (3, 0), size: 2 × 1),
            .init(position: (finalRowX, 2), size: 2 × 1),
        ]
    )
}

private func assertVFlowHorizontalAlignment(_ alignment: HorizontalAlignment, narrowItemX: CGFloat) {
    FlowLayoutScenario(
        layout: .vertical(horizontalAlignment: alignment, verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 1),
        subviews: [3 × 2, 1 × 2],
        proposal: 3 × 5
    )
    .assertExpectedLayout(
        size: 3 × 5,
        placements: [
            .init(position: (0, 0), size: 3 × 2),
            .init(position: (narrowItemX, 3), size: 1 × 2),
        ]
    )
}

private func assertVFlowVerticalAlignment(_ alignment: VerticalAlignment, finalColumnY: CGFloat) {
    FlowLayoutScenario(
        layout: .vertical(
            horizontalAlignment: .leading,
            verticalAlignment: alignment,
            horizontalSpacing: 1,
            verticalSpacing: 1
        ),
        subviews: [1 × 2, 1 × 2, 1 × 2],
        proposal: 10 × 5
    )
    .assertExpectedLayout(
        size: 3 × 5,
        placements: [
            .init(position: (0, 0), size: 1 × 2),
            .init(position: (0, 3), size: 1 × 2),
            .init(position: (2, finalColumnY), size: 1 × 2),
        ]
    )
}
