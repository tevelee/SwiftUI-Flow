import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements, .regression))
struct FlowCacheRequirementTests {
    @Test(arguments: [false, true], [false, true])
    func crossAxisResize_rewrapsAspectRatioContent(vertical: Bool, evenly: Bool) {
        let subviews: [TestSubview] = (0 ..< 2).map { _ in SquareSubview(minSize: .zero, idealSize: 20 × 20, maxSize: 20 × 20) }
        subviews.forEach { $0[FlexibilityLayoutValueKey.self] = .minimum }
        let layout = FlowLayout(
            axis: vertical ? .vertical : .horizontal,
            itemSpacing: 0,
            lineSpacing: 0,
            distributeItemsEvenly: evenly,
            alignmentOnBreadth: { _ in 0 },
            alignmentOnDepth: { _ in 0 }
        )
        var cache = layout.makeCache(subviews)

        // With unchanged breadth, deeper squares require two lines instead of one.
        // Resize back as well: keeping the previous line partition would leave a stale wrap.
        for depth: CGFloat in [5, 10, 5] {
            let proposal = ProposedViewSize(width: vertical ? depth : 15, height: vertical ? 15 : depth)
            let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
            layout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: proposal, subviews: subviews, cache: &cache)

            let wraps = depth == 10
            let totalDepth: CGFloat = wraps ? 20 : 5
            #expect(size == CGSize(width: vertical ? totalDepth : 10, height: vertical ? 10 : totalDepth))
            let second = wraps ? CGPoint(x: 0, y: 10) : CGPoint(x: 5, y: 0)
            expectPlacements(
                subviews,
                [
                    .init(position: (0, 0), size: CGSize(width: depth, height: depth)),
                    .init(position: vertical ? (second.y, second.x) : (second.x, second.y), size: CGSize(width: depth, height: depth)),
                ]
            )
        }
    }
}

/// Models square content whose fitted breadth depends on the proposed cross-axis extent.
private final class SquareSubview: TestSubview {
    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let side = min(20, min(proposal.width ?? 20, proposal.height ?? 20))
        return CGSize(width: side, height: side)
    }
}
