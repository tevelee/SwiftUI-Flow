import CoreFoundation
import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowInputPreparationRequirementTests {
    @Test(arguments: [false, true], [false, true])
    func cappedContent_measuresOnlyBreakerItems(vertical: Bool, separators: Bool) {
        let content = (0 ..< 2).map { _ in CountingSubview(size: size(breadth: 30, vertical: vertical)) }
        let overflow = CountingSubview(size: size(breadth: 20, vertical: vertical))
        overflow[FlowSubviewOriginLayoutValueKey.self] = .overflowBuilder
        let separator = CountingSubview(size: size(breadth: 15, vertical: vertical))
        separator[FlowSubviewRoleLayoutValueKey.self] = .itemSeparator
        let subviews: [TestSubview] = separators ? [content[0], separator, content[1], overflow] : content + [overflow]
        let layout: FlowLayout =
            vertical
            ? .vertical(horizontalSpacing: 0, verticalSpacing: 0, maxLines: 0)
            : .horizontal(horizontalSpacing: 0, verticalSpacing: 0, maxLines: 0)
        var cache = layout.makeCache(subviews)
        // Every ideal breadth exceeds this proposal, so entering the breaker requires a fresh
        // measurement. A zero cap then hides everything, avoiding later geometry measurements.
        let proposal = ProposedViewSize(width: vertical ? 100 : 10, height: vertical ? 10 : 100)
        let result = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)

        #expect(result == .zero)
        #expect(content.map(\.measurementCount) == [1, 1])
        #expect(overflow.measurementCount == 0, "Overflow fitting uses the cached ideal size")
        #expect(separator.measurementCount == 0, "Separator breadth comes from the cached ideal size")
    }

    @Test(arguments: [false, true], [false, true])
    func cacheRefresh_rebuildsSeparatorRelationships(vertical: Bool, evenly: Bool) {
        let first = TestSubview(size: size(breadth: 30, vertical: vertical))
        let boundary = TestSubview(size: size(breadth: 5, vertical: vertical))
        let last = TestSubview(size: size(breadth: 30, vertical: vertical))
        let subviews = [first, boundary, last]
        let layout: FlowLayout =
            vertical
            ? .vertical(horizontalSpacing: 0, verticalSpacing: 0, distributeItemsEvenly: evenly)
            : .horizontal(horizontalSpacing: 0, verticalSpacing: 0, distributeItemsEvenly: evenly)
        var cache = layout.makeCache(subviews)
        let cases: [(role: FlowSubviewRole, breadth: CGFloat, depth: CGFloat)] = [
            (.content, 35, 20),
            (.itemSeparator, 30, 20),
            (.itemSeparatorOverride(isEmpty: false), 30, 20),
            (.itemSeparatorOverride(isEmpty: true), 60, 10),
            (.content, 35, 20),
        ]
        let proposal = ProposedViewSize(width: vertical ? 100 : 60, height: vertical ? 60 : 100)
        for scenario in cases {
            boundary[FlowSubviewRoleLayoutValueKey.self] = scenario.role
            layout.refreshCache(&cache, subviews: subviews)
            let expected = size(breadth: scenario.breadth, depth: scenario.depth, vertical: vertical)
            #expect(layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache) == expected)
            // Reusing the prepared input must preserve the same result on subsequent passes.
            #expect(layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache) == expected)
        }
    }

    private func size(breadth: CGFloat, depth: CGFloat = 10, vertical: Bool) -> CGSize {
        CGSize(width: vertical ? depth : breadth, height: vertical ? breadth : depth)
    }
}

private final class CountingSubview: TestSubview {
    var measurementCount = 0

    override func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        measurementCount += 1
        return super.sizeThatFits(proposal)
    }
}
