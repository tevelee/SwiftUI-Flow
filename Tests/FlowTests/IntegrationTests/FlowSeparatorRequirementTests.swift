import CoreFoundation
import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowSeparatorRequirementTests {
    // MARK: - Item separators

    @Test func itemSeparator_isPlacedBetweenTwoItemsOnTheSameLine() {
        // [c0(30) | sep(10) | c1(30)] all fit on one line with itemSpacing 0.
        let subviews = interleaved(
            content: [30 × 10, 30 × 10],
            itemSeparator: { 10 × 10 }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        FlowLayoutScenario(
            layout: sut,
            subviews: subviews,
            proposal: 100 × 100
        )
        .assertExpectedLayout(
            size: 70 × 10,
            placements: [
                .init(position: (0, 0), size: 30 × 10),
                .init(position: (30, 0), size: 10 × 10),
                .init(position: (40, 0), size: 30 × 10),
            ]
        )
    }

    @Test func itemSeparator_widthIsAccountedForWhenBreakingLines() {
        // Without the separator both 30-wide items fit in 70. The 20-wide separator pushes the
        // second item onto its own line, proving the separator consumes line-breaking space.
        let subviews = interleaved(
            content: [30 × 10, 30 × 10],
            itemSeparator: { 20 × 10 }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = FlowLayoutScenario(layout: sut, subviews: subviews, proposal: 70 × 100).layoutThatFits()
        // Two lines now (c0 alone, c1 alone); the in-line separator is dropped at the break.
        #expect(result.subviews[0].placement?.position == CGPoint(x: 0, y: 0))  // c0
        #expect(result.subviews[2].placement?.position == CGPoint(x: 0, y: 10))  // c1 wrapped below
        #expect(isParked(result.subviews[1], in: result.reportedSize))  // separator suppressed
    }

    // MARK: - Line separators

    @Test func lineSeparator_becomesItsOwnLineBetweenRows() {
        // Two 50-wide items in 50 points of width wrap; the full-width line separator sits between them.
        let subviews = interleaved(
            content: [50 × 10, 50 × 10],
            lineSeparator: { stretchingSeparator(depth: 2) }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        FlowLayoutScenario(
            layout: sut,
            subviews: subviews,
            proposal: 50 × 200,
            bounds: CGRect(x: 0, y: 0, width: 50, height: 200)
        )
        .assertExpectedLayout(
            size: 50 × 22,
            placements: [
                .init(position: (0, 0), size: 50 × 10),
                .init(position: (0, 10), size: 50 × 2),
                .init(position: (0, 12), size: 50 × 10),
            ]
        )
    }

    @Test func lineSeparator_lineSpacingAppliesOnBothSides() {
        // With verticalSpacing=8, the normal 8pt gap sits on each side of the separator:
        // 8pt between row 0 and the separator, and 8pt between the separator and row 1.
        let subviews = interleaved(
            content: [50 × 10, 50 × 10],
            lineSeparator: { stretchingSeparator(depth: 2) }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 8)
        FlowLayoutScenario(
            layout: sut,
            subviews: subviews,
            proposal: 50 × 200,
            bounds: CGRect(x: 0, y: 0, width: 50, height: 200)
        )
        .assertExpectedLayout(
            size: 50 × 38,
            placements: [
                .init(position: (0, 0), size: 50 × 10),  // row 0
                .init(position: (0, 18), size: 50 × 2),  // separator with 8pt gap on each side
                .init(position: (0, 28), size: 50 × 10),  // row 1
            ]
        )
    }

    // MARK: - The item/line swap

    @Test func gapDrawsItemSeparatorInline_orLineSeparatorWhenWrapped() {
        // Same gap owns both separators. On one line the item separator shows; when the gap wraps,
        // the item separator is dropped and the line separator is drawn instead.
        let subviews = interleaved(
            content: [50 × 10, 50 × 10],
            itemSeparator: { 8 × 10 },
            lineSeparator: { stretchingSeparator(depth: 2) }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        FlowLayoutScenario(
            layout: sut,
            subviews: subviews,
            proposal: 50 × 100,
            bounds: CGRect(x: 0, y: 0, width: 50, height: 100)
        )
        .assertExpectedLayout(
            size: 50 × 22,
            placements: [
                .init(position: (0, 0), size: 50 × 10),  // c0
                .init(position: (0, 100 + 1_000_000), size: 8 × 10),  // item separator parked off-screen
                .init(position: (0, 10), size: 50 × 2),  // line separator drawn instead
                .init(position: (0, 12), size: 50 × 10),  // c1
            ]
        )
    }

    // MARK: - maxLines interaction

    @Test func lineStructure_assignsSentinelToHiddenItems() {
        // 3 content items with line separators. Only the first two are "visible" — the third is capped.
        // lineStructure must return hiddenLineSentinel for the capped item so the view layer does not
        // inject a spurious separator at that boundary.
        let subviews = interleaved(
            content: [10 × 10, 10 × 10, 10 × 10],
            lineSeparator: { stretchingSeparator(depth: 1) }
        )
        // subview order: c0(0), lineSep(1), c1(2), lineSep(3), c2(4)  →  contentIndices = [0, 2, 4]
        let cache = FlowLayoutCache(subviews, axis: .horizontal)
        let separators = SeparatorLayout(cache: cache, axis: .horizontal, itemSpacing: 0)!

        let visible: LineBreakingOutput = [
            [LineItemOutput(index: 0, size: 10, leadingSpace: 0)],
            [LineItemOutput(index: 2, size: 10, leadingSpace: 0)],
            // subview index 4 (c2) is absent — capped
        ]
        let lineOf = separators.lineStructure(of: visible)

        #expect(lineOf == [0, 1, SeparatorLayout.hiddenLineSentinel])
    }

    // MARK: - Edges & invariants

    @Test func separators_neverAppearAtTheEdges() {
        // Three items on one line: exactly two item separators, both strictly between items.
        let subviews = interleaved(
            content: [20 × 10, 20 × 10, 20 × 10],
            itemSeparator: { 5 × 10 }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = FlowLayoutScenario(layout: sut, subviews: subviews, proposal: 200 × 100).layoutThatFits()
        // Subview order: c0, sep, c1, sep, c2
        let xs = result.subviews.compactMap { $0.placement?.position.x }
        #expect(xs == [0, 20, 25, 45, 50])
        // Nothing sits before the first item (x >= 0) or after the last (max right edge == c2 right).
        #expect(result.reportedSize.width == 70)
    }

    @Test func singleItem_hasNoSeparators() {
        let subviews = interleaved(content: [30 × 10], itemSeparator: { 10 × 10 }, lineSeparator: { 10 × 2 })
        // A single item produces no gaps, hence no separator subviews are injected at all.
        #expect(subviews.count == 1)
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        FlowLayoutScenario(
            layout: sut,
            subviews: subviews,
            proposal: 100 × 100
        )
        .assertExpectedSize(30 × 10)
    }

    @Test func separatorsAroundManualLineBreak_areSuppressed() {
        // c0, break, c1 — the break forces a new line and the touching separators are hidden.
        let breakView = testLineBreakSubview()
        let subviews = interleaved(
            content: [30 × 10, breakView, 30 × 10],
            itemSeparator: { 10 × 10 },
            lineSeparator: { 10 × 2 }
        )
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = FlowLayoutScenario(layout: sut, subviews: subviews, proposal: 200 × 100).layoutThatFits()
        // Every injected separator (indices around the break) is parked off-screen.
        for subview in result.subviews where subview[SeparatorRoleLayoutValueKey.self] != .content {
            #expect(isParked(subview, in: result.reportedSize))
        }
    }

    // MARK: - Helpers

    /// Interleaves item/line separators between the given content subviews, mirroring what the
    /// `_VariadicView` interleaver produces: `c0, [itemSep], [lineSep], c1, …` with none at the edges.
    private func interleaved(
        content: [TestSubview],
        itemSeparator: (() -> TestSubview)? = nil,
        lineSeparator: (() -> TestSubview)? = nil
    ) -> [TestSubview] {
        var result: [TestSubview] = []
        for (offset, item) in content.enumerated() {
            result.append(item)
            guard offset < content.count - 1 else { continue }
            if let itemSeparator {
                let separator = itemSeparator()
                separator[SeparatorRoleLayoutValueKey.self] = .itemSeparator
                result.append(separator)
            }
            if let lineSeparator {
                let separator = lineSeparator()
                separator[SeparatorRoleLayoutValueKey.self] = .lineSeparator
                result.append(separator)
            }
        }
        return result
    }

    /// A separator that stretches along the breadth axis (like a `Divider`) but keeps a fixed depth.
    private func stretchingSeparator(depth: CGFloat) -> TestSubview {
        TestSubview(
            minSize: CGSize(width: 0, height: depth),
            idealSize: CGSize(width: 0, height: depth),
            maxSize: CGSize(width: .infinity, height: depth)
        )
    }

    /// Whether a subview was placed far outside the laid-out bounds (i.e. hidden/suppressed).
    private func isParked(_ subview: TestSubview, in size: CGSize) -> Bool {
        guard let y = subview.placement?.position.y else { return false }
        return y > size.height + 1000
    }
}
