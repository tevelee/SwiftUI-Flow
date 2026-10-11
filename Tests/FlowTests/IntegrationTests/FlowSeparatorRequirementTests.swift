import CoreFoundation
import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct FlowSeparatorRequirementTests {
    @Test(arguments: [false, true])
    func explicitSeparator_yieldsToLineSeparatorWhenWrapped(evenly: Bool) {
        let separator: TestSubview = 20 × 10
        separator[SeparatorRoleLayoutValueKey.self] = .itemSeparatorOverride(isEmpty: false)
        let subviews = interleaved(
            content: [30 × 10, separator, 30 × 10],
            itemSeparator: { 5 × 10 },
            lineSeparator: { stretchingSeparator(depth: 2) }
        )
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 5, verticalSpacing: 0, distributeItemsEvenly: evenly),
            subviews: subviews,
            proposal: 89 × 100
        ).layoutThatFits()
        #expect(result.reportedSize == (30 × 22))
        #expect(subviews[0].placement?.position == .zero)
        #expect(subviews[5].placement?.position == CGPoint(x: 0, y: 10))
        #expect(subviews[6].placement?.position == CGPoint(x: 0, y: 12))
        #expect([1, 2, 3, 4].allSatisfy { isParked(subviews[$0], in: result.reportedSize) })
        let cache = FlowLayoutCache(subviews, axis: .horizontal)
        let separators = SeparatorLayout(cache: cache, axis: .horizontal, itemSpacing: 5)!
        #expect(separators.lineStructure(of: [[.init(index: 0, size: 30, leadingSpace: 0)], [.init(index: 6, size: 30, leadingSpace: 0)]]) == [0, 0, 1])
    }

    @Test func explicitSeparators_doNotCountAsHiddenItems() {
        final class Counts: @unchecked Sendable { var value: Int? }
        let counts = Counts()
        let custom: TestSubview = 20 × 10
        custom[SeparatorRoleLayoutValueKey.self] = .itemSeparatorOverride(isEmpty: false)
        let empty: TestSubview = 0 × 0
        empty[SeparatorRoleLayoutValueKey.self] = .itemSeparatorOverride(isEmpty: true)
        let overflow: TestSubview = 10 × 10
        overflow[IsOverflowLayoutValueKey.self] = true
        overflow[OverflowReporterKey.self] = { counts.value = $0 }
        let subviews = interleaved(content: [30 × 10, custom, 30 × 10, empty, 30 × 10], itemSeparator: { 5 × 10 }) + [overflow]
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 2, verticalSpacing: 0, maxLines: 1),
            subviews: subviews,
            proposal: 85 × 100
        ).layoutThatFits()
        #expect(result.reportedSize == (64 × 10))
        #expect(custom.placement?.position == CGPoint(x: 32, y: 0))
        #expect(overflow.placement?.position == CGPoint(x: 54, y: 0))
        #expect(counts.value == 2)
    }

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
                .init(position: (0, CGFloat(100 + 1_000_000)), size: 8 × 10),  // item separator parked off-screen
                .init(position: (0, 10), size: 50 × 2),  // line separator drawn instead
                .init(position: (0, 12), size: 50 × 10),  // c1
            ]
        )
    }

    // MARK: - maxLines interaction

    @Test(arguments: [false, true], [false, true])
    func overflowIndicator_reusesSeparatorAfterLastVisibleItem(vertical: Bool, evenly: Bool) {
        let content: [TestSubview] = vertical ? [10 × 30, 10 × 30, 10 × 30] : [30 × 10, 30 × 10, 30 × 10]
        let subviews = interleaved(
            content: content,
            itemSeparator: { vertical ? 10 × 5 : 5 × 10 },
            lineSeparator: { 2 × 2 }
        )
        let overflow: TestSubview = 10 × 10
        overflow[IsOverflowLayoutValueKey.self] = true
        let sut: FlowLayout =
            vertical
            ? .vertical(horizontalSpacing: 0, verticalSpacing: 2, distributeItemsEvenly: evenly, maxLines: 1)
            : .horizontal(horizontalSpacing: 2, verticalSpacing: 0, distributeItemsEvenly: evenly, maxLines: 1)
        let result = FlowLayoutScenario(
            layout: sut,
            subviews: subviews + [overflow],
            proposal: vertical ? 100 × 85 : 85 × 100
        ).layoutThatFits()

        #expect(result.reportedSize == (vertical ? 10 × 49 : 49 × 10))
        #expect(content[0].placement?.position == .zero)
        #expect(subviews[1].placement?.position == CGPoint(x: vertical ? 0 : 32, y: vertical ? 32 : 0))
        #expect(overflow.placement?.position == CGPoint(x: vertical ? 0 : 39, y: vertical ? 39 : 0))
        #expect(content.dropFirst().allSatisfy { isHidden($0, vertical: vertical) })
        #expect(
            subviews.dropFirst(2).filter { $0[SeparatorRoleLayoutValueKey.self].isSeparator }.allSatisfy {
                isHidden($0, vertical: vertical)
            }
        )
    }

    @Test func overflowIndicator_alone_hasNoSeparatorOrLeadingSpacing() {
        let subviews = interleaved(content: [30 × 10, 30 × 10], itemSeparator: { 5 × 10 })
        let overflow: TestSubview = 10 × 10
        overflow[IsOverflowLayoutValueKey.self] = true
        let result = FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 2, verticalSpacing: 0, maxLines: 1),
            subviews: subviews + [overflow],
            proposal: 35 × 100
        ).layoutThatFits()
        #expect(result.reportedSize == (10 × 10))
        #expect(overflow.placement?.position == .zero)
        #expect(subviews.allSatisfy { isHidden($0, vertical: false) })
    }

    private func isHidden(_ subview: TestSubview, vertical: Bool) -> Bool {
        guard let position = subview.placement?.position else { return false }
        return position.y > 1000
    }

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

        let visible: WrappedLines = [
            [WrappedItem(index: 0, size: 10, leadingSpace: 0)],
            [WrappedItem(index: 2, size: 10, leadingSpace: 0)],
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
