import SwiftUI
import Testing

@testable import Flow

/// Justification stretches the gaps between items to fill leftover space. If a line's
/// measured content overflows the available space — which happens when a subview reports
/// a larger size than it was proposed (e.g. a `Text` with a long unbreakable word, or a
/// fixed-frame view the line breaker underestimated) — there is no leftover space to
/// distribute. The layout must not respond by pulling items together into an overlap.
@Suite(.tags(.requirements, .regression))
struct FlowJustifiedOverflowRequirementTests {
    @Test func HFlow_justified_overflowingLine_doesNotOverlapItems() throws {
        let a = OverMeasuringSubview(ideal: 4 × 2, measured: 8 × 2)
        let b = OverMeasuringSubview(ideal: 4 × 2, measured: 8 × 2)

        // The breaker packs both onto one line using their ideal breadth (4 + 4 ≤ 10),
        // but each measures 8 at placement, so the line's content (16) overflows the 10pt
        // proposal. Justification has nothing to add and must leave the items disjoint.
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [a, b],
            proposal: 10 × 4
        )
        .layoutThatFits()

        let placementA = try #require(a.placement)
        let placementB = try #require(b.placement)
        #expect(
            placementB.position.x + tolerance >= placementA.position.x + placementA.size.width,
            "Justified overflow must not pull the trailing item back over the leading one"
        )
    }

    @Test func VFlow_justified_overflowingLine_doesNotOverlapItems() throws {
        let a = OverMeasuringSubview(ideal: 2 × 4, measured: 2 × 8)
        let b = OverMeasuringSubview(ideal: 2 × 4, measured: 2 × 8)

        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true),
            subviews: [a, b],
            proposal: 4 × 10
        )
        .layoutThatFits()

        let placementA = try #require(a.placement)
        let placementB = try #require(b.placement)
        #expect(
            placementB.position.y + tolerance >= placementA.position.y + placementA.size.height,
            "Justified overflow must not pull the trailing item back over the leading one"
        )
    }
}

private let tolerance: CGFloat = 0.000_001

/// A subview that reports its small `ideal` size for unconstrained proposals (so the line
/// breaker packs it tightly) but a larger `measured` size whenever it is given a concrete
/// proposal — mimicking a real view whose minimum intrinsic size exceeds what it was offered.
private final class OverMeasuringSubview: TestSubview {
    private let measured: CGSize

    init(ideal: CGSize, measured: CGSize) {
        self.measured = measured
        super.init(size: ideal)
    }

    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        switch proposal {
            case .unspecified, .infinity, .zero: super.sizeThatFits(proposal)
            default: measured
        }
    }

    override func dimensions(_ proposal: ProposedViewSize) -> any Dimensions {
        switch proposal {
            case .unspecified, .infinity, .zero: super.dimensions(proposal)
            default: FixedDimensions(width: measured.width, height: measured.height)
        }
    }
}

private struct FixedDimensions: Dimensions {
    let width: CGFloat
    let height: CGFloat
    subscript(guide: HorizontalAlignment) -> CGFloat {
        switch guide {
            case .center: 0.5 * width
            case .trailing: width
            default: 0
        }
    }
    subscript(guide: VerticalAlignment) -> CGFloat {
        switch guide {
            case .center: 0.5 * height
            case .bottom: height
            default: 0
        }
    }
}
