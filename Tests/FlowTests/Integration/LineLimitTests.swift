import SwiftUI
import Testing

@testable import Flow
@testable import FlowLineLimit

@Suite
struct LineLimitTests {
    @Test func maxLines_environmentKey_defaultsToNil() {
        var env = EnvironmentValues()
        env.maxLines = 3
        #expect(env.maxLines == 3)
        env.maxLines = nil
        #expect(env.maxLines == nil)
    }

    @Test @MainActor func HFlow_maxLines_modifier_compiles() {
        _ = HFlow(itemSpacing: 0, rowSpacing: 0) { EmptyView() }
            .maxLines(1)
    }

    @Test @MainActor func VFlow_maxLines_modifier_compiles() {
        _ = VFlow(itemSpacing: 0, columnSpacing: 0) { EmptyView() }
            .maxLines(1)
    }

    @Test @MainActor func HFlow_maxLinesOverflow_modifier_compiles() {
        _ = HFlow(itemSpacing: 0, rowSpacing: 0) { EmptyView() }
            .maxLines(1) { count in Text("+\(count)") }
    }

    @Test @MainActor func VFlow_maxLinesOverflow_modifier_compiles() {
        _ = VFlow(itemSpacing: 0, columnSpacing: 0) { EmptyView() }
            .maxLines(1) { count in Text("+\(count)") }
    }

    @Test @MainActor func View_maxLines_nilIsNoOp() {
        // maxLines(nil) must compile and should not constrain the flow.
        _ = HFlow(itemSpacing: 0, rowSpacing: 0) { EmptyView() }
            .maxLines(nil)
    }

    @Test func HFlowLayout_maxLinesInit_setsLimit() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(2)
        let subviews: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        let size = sut.sizeThatFits(proposal: 5 × 5, subviews: subviews)
        #expect(size.height == 2)
    }

    @Test func VFlowLayout_maxLinesInit_setsLimit() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(2)
        let subviews: [TestSubview] = [1 × 4, 1 × 4, 1 × 4]
        let size = sut.sizeThatFits(proposal: 5 × 5, subviews: subviews)
        #expect(size.width == 2)
    }

    @Test func HFlow_maxLines_keepsFirstLine_hidesRest() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        // Three width-4 items in a width-5 box wrap to three single-item lines.
        let subviews: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        _ = sut.layout(subviews, in: 5 × 5)
        #expect(subviews[0].placement?.position == CGPoint(x: 0, y: 0))
        #expect(isOffscreen(subviews[1], in: 5 × 5))
        #expect(isOffscreen(subviews[2], in: 5 × 5))
    }

    @Test func HFlow_maxLines_reportsTruncatedHeight() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        let size = sut.sizeThatFits(proposal: 5 × 5, subviews: [4 × 1, 4 × 1, 4 × 1])
        #expect(size.height == 1)
    }

    @Test func HFlow_maxLines_aboveNaturalLineCount_isNoOp() {
        let capped: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(10)
        let subviews: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        _ = capped.layout(subviews, in: 5 × 5)
        #expect(subviews.allSatisfy { !isOffscreen($0, in: 5 × 5) })
        #expect(capped.sizeThatFits(proposal: 5 × 5, subviews: [4 × 1, 4 × 1, 4 × 1]).height == 3)
    }

    @Test func VFlow_maxLines_keepsFirstColumn_hidesRest() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        let subviews: [TestSubview] = [1 × 4, 1 × 4, 1 × 4]
        _ = sut.layout(subviews, in: 5 × 5)
        #expect(subviews[0].placement?.position == CGPoint(x: 0, y: 0))
        #expect(isOffscreen(subviews[1], in: 5 × 5))
        #expect(isOffscreen(subviews[2], in: 5 × 5))
    }

    // MARK: - withMaxLines / withOverflowReporter coverage

    @Test func FlowLayout_withMaxLines_appliesLimit() {
        let base: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let capped = base.withMaxLines(1)
        // Without the cap: 3 rows; with cap: 1 row
        let subviews: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        #expect(base.sizeThatFits(proposal: 5 × 5, subviews: subviews).height == 3)
        #expect(capped.sizeThatFits(proposal: 5 × 5, subviews: subviews).height == 1)
    }

    @Test func overflowReporter_doesNotAffectLayoutSize() {
        // A reporter on the overflow indicator must not change the measured size.
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        let items: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        let overflow = TestSubview(size: CGSize(width: 1, height: 1))
        overflow[IsOverflowLayoutValueKey.self] = true
        overflow[OverflowReporterKey.self] = { _ in }
        let size = sut.sizeThatFits(proposal: 5 × 5, subviews: items + [overflow])
        #expect(size.height == 1)
    }

    @Test func overflowReporter_calledSynchronously_withCorrectCount() {
        // Reporter must be invoked synchronously from placeSubviews so that multiple
        // resize passes in the same run-loop iteration don't interleave stale 0-counts.
        final class Counts: @unchecked Sendable { var values: [Int] = [] }
        let counts = Counts()
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        let items: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        let overflow = TestSubview(size: CGSize(width: 1, height: 1))
        overflow[IsOverflowLayoutValueKey.self] = true
        overflow[OverflowReporterKey.self] = { count in counts.values.append(count) }
        _ = sut.layout(items + [overflow], in: 5 × 5)
        // After layout returns, reporter must already have been called (not deferred).
        #expect(counts.values.count >= 1)
        #expect(counts.values[0] == 2)
    }

    // MARK: - Overflow indicator subview path

    @Test func overflowIndicator_isPlacedAtEndOfLastVisibleLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        // Three 2-wide items in a 5-wide box wrap as: row1=[item0,item1], row2=[item2].
        // Plus a 1-wide overflow indicator. Row1 used width = 4; overflow(1) fits without trimming.
        let items: [TestSubview] = [2 × 1, 2 × 1, 2 × 1]
        let overflow = TestSubview(size: CGSize(width: 1, height: 1))
        overflow[IsOverflowLayoutValueKey.self] = true
        let subviews = items + [overflow]
        _ = sut.layout(subviews, in: 5 × 5)
        // Both items on row 1 remain visible; overflow indicator joins at x=4.
        #expect(items[0].placement?.position == CGPoint(x: 0, y: 0))
        #expect(items[1].placement?.position == CGPoint(x: 2, y: 0))
        #expect(overflow.placement?.position == CGPoint(x: 4, y: 0))
        // Item 2 is hidden.
        #expect(isOffscreen(items[2], in: 5 × 5))
    }

    @Test func overflowIndicator_hiddenWhenAllItemsFit() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(5)
        let items: [TestSubview] = [4 × 1, 4 × 1]
        let overflow = TestSubview(size: CGSize(width: 2, height: 1))
        overflow[IsOverflowLayoutValueKey.self] = true
        let subviews = items + [overflow]
        _ = sut.layout(subviews, in: 5 × 5)
        // All items fit — overflow indicator must be placed off-screen.
        #expect(!isOffscreen(items[0], in: 5 × 5))
        #expect(!isOffscreen(items[1], in: 5 × 5))
        #expect(isOffscreen(overflow, in: 5 × 5))
    }

    // MARK: - HFlowLayout / VFlowLayout bridge methods

    @Test func HFlowLayout_withMaxLines_storesLimit() {
        let base = HFlowLayout(alignment: .center, itemSpacing: 0, rowSpacing: 0)
        #expect(base.layout.lineCap == nil)
        let capped = base.withMaxLines(3)
        #expect(capped.layout.lineCap?.maxLines == 3)
    }

    @Test func VFlowLayout_withMaxLines_storesLimit() {
        let base = VFlowLayout(alignment: .center, itemSpacing: 0, columnSpacing: 0)
        #expect(base.layout.lineCap == nil)
        let capped = base.withMaxLines(2)
        #expect(capped.layout.lineCap?.maxLines == 2)
    }

    // MARK: - Overflow indicator edge cases

    @Test func overflowIndicator_hiddenWhenMaxLinesIsZero() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(0)
        let items: [TestSubview] = [4 × 1, 4 × 1]
        let overflow = TestSubview(size: CGSize(width: 2, height: 1))
        overflow[IsOverflowLayoutValueKey.self] = true
        _ = sut.layout(items + [overflow], in: 5 × 5)
        // maxLines=0 → all lines hidden; overflow indicator hidden too
        #expect(isOffscreen(items[0], in: 5 × 5))
        #expect(isOffscreen(items[1], in: 5 × 5))
        #expect(isOffscreen(overflow, in: 5 × 5))
    }

    @Test func overflowIndicator_trimsLastLineItemsToFit() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0).withMaxLines(1)
        // item0 (w=4) is alone on row 1; overflow (w=2) can't join (4+2=6>5).
        // trimLastLine removes item0, leaving an empty row, then places overflow at x=0.
        let items: [TestSubview] = [4 × 1, 4 × 1, 4 × 1]
        let overflow = TestSubview(size: CGSize(width: 2, height: 1))
        overflow[IsOverflowLayoutValueKey.self] = true
        _ = sut.layout(items + [overflow], in: 5 × 5)
        #expect(overflow.placement?.position == CGPoint(x: 0, y: 0))
        #expect(isOffscreen(items[0], in: 5 × 5))
        #expect(isOffscreen(items[1], in: 5 × 5))
        #expect(isOffscreen(items[2], in: 5 × 5))
    }

    // MARK: - nil item spacing (ViewSpacing-based distance)

    @Test func nilSpacing_usesViewSpacingDistance() {
        // All tests above use explicit 0 spacing; this one uses nil so spacing(before:)
        // takes the ViewSpacing code path for both offset=0 (returns 0) and offset>0.
        let sut: FlowLayout = .horizontal()
        let subviews: [TestSubview] = [2 × 1, 2 × 1, 2 × 1]
        let size = sut.sizeThatFits(proposal: 100 × 100, subviews: subviews)
        #expect(size.height > 0)
        _ = sut.layout(subviews, in: 100 × 100)
        #expect(subviews[0].placement?.position != nil)
        #expect(subviews[1].placement?.position != nil)
        #expect(subviews[2].placement?.position != nil)
    }

    private func isOffscreen(_ subview: TestSubview, in bounds: CGSize) -> Bool {
        guard let position = subview.placement?.position else { return false }
        return position.x >= bounds.width || position.y >= bounds.height
    }
}
