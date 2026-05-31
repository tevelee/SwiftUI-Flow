import SwiftUI
import Testing

@testable import Flow

@Suite
struct LayoutEngineTests {
    @Test func HFlow_lineBreak_forcesNewRow() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3 × 1, lineBreakSubview(), 3 × 1], in: 10 × 2)
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                |XXX       |
                +----------+
                """
        )
    }

    @Test func HFlow_lineBreak_atStart() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([lineBreakSubview(), 3 × 1], in: 10 × 1)
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                +----------+
                """
        )
    }

    @Test func HFlow_lineBreak_atEnd() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3 × 1, lineBreakSubview()], in: 10 × 1)
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                +----------+
                """
        )
    }

    @Test func HFlow_startInNewLine_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3 × 1, 3 × 1, newLineSubview(3 × 1)], in: 10 × 2)
        #expect(
            render(result) == """
                +----------+
                |XXX XXX   |
                |XXX       |
                +----------+
                """
        )
    }

    @Test func HFlow_startInNewLine_first() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([newLineSubview(3 × 1), 3 × 1], in: 10 × 1)
        #expect(
            render(result) == """
                +----------+
                |XXX XXX   |
                +----------+
                """
        )
    }

    @Test func HFlow_justified_threeItems() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([2 × 1, 2 × 1, 2 × 1], in: 10 × 1)
        #expect(
            render(result) == """
                +----------+
                |XX  XX  XX|
                +----------+
                """
        )
    }

    @Test func HFlow_justified_singleItem() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([5 × 1], in: 10 × 1)
        #expect(
            render(result) == """
                +----------+
                |XXXXX     |
                +----------+
                """
        )
    }

    @Test func VFlow_justified_sizeThatFits() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true)
        let size = sut.sizeThatFits(proposal: 1 × 6, subviews: [1 × 2, 1 × 2, 1 × 2])
        #expect(size.height == 6)
    }

    @Test func VFlow_distributed_sizeThatFits() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true)
        let size = sut.sizeThatFits(proposal: 2 × 5, subviews: repeated(1 × 1, times: 5))
        #expect(size.width > 0)
    }

    @Test func HFlow_emptySubviews() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let size = sut.sizeThatFits(proposal: 100 × 100, subviews: [TestSubview]())
        #expect(size == CGSize.zero)
    }

    @Test func HFlow_singleItem_centered() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3 × 1, 3 × 1, 3 × 1], in: 10 × 2)
        #expect(
            render(result) == """
                +----------+
                |XXX XXX   |
                |  XXX     |
                +----------+
                """
        )
    }

    @Test func HFlow_zeroSizeItems_noAlignmentCrash() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0)
        let zero1 = TestSubview(size: .zero)
        let zero2 = TestSubview(size: .zero)
        let size = sut.sizeThatFits(
            proposal: ProposedViewSize(width: 100, height: 100),
            subviews: [zero1, zero2]
        )
        #expect(size == CGSize.zero)
    }

    // MARK: - Edge Cases

    @Test func HFlow_singleItemLargerThanContainer() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let size = sut.sizeThatFits(proposal: 5 × 5, subviews: [10 × 3])
        // An item wider than the container is placed on its own line at its natural size.
        #expect(size == (10 × 3 as CGSize))
    }

    @Test func HFlow_oversizedItem_doesNotDropNeighbours() {
        // [A=3, B=10(overflow), C=3, D=3] in a container of width 5, spacing 0.
        // B exceeds the available width but must still appear; C and D must not be dropped.
        // With spacing=0: 3+3=6 > 5, so C and D each get their own row → 4 rows total.
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let items: [TestSubview] = [3 × 1, 10 × 1, 3 × 1, 3 × 1]
        let size = sut.sizeThatFits(proposal: 5 × 4, subviews: items)
        #expect(size.height == 4, "All 4 items must be placed (none dropped)")
        #expect(size.width == 10, "Widest line is the overflow item")
    }

    @Test func HFlow_distributeEvenly_oversizedItem_isPlaced() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0, distributeItemsEvenly: true)
        let size = sut.sizeThatFits(proposal: 5 × 5, subviews: [10 × 3])
        #expect(size == (10 × 3 as CGSize))
    }

    @Test func HFlow_zeroProposal() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let size = sut.sizeThatFits(proposal: 0 × 0, subviews: [3 × 2, 4 × 2])
        #expect(size.width >= 0)
        #expect(size.height >= 0)
    }

    @Test func HFlow_infinityProposal() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let items: [TestSubview] = [3 × 2, 4 × 2, 5 × 2]
        let size = sut.sizeThatFits(proposal: ProposedViewSize(width: .infinity, height: .infinity), subviews: items)
        // With infinite width, all items should fit on one line
        #expect(size == (14 × 2 as CGSize))
    }

    @Test func HFlow_negativeSpacing() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: -2, verticalSpacing: 0)
        let size = sut.sizeThatFits(proposal: 100 × 100, subviews: [5 × 3, 5 × 3, 5 × 3])
        // Items should overlap with negative spacing
        #expect(size.width < 15, "Negative spacing should reduce total width")
        #expect(size.width > 0)
    }

    @Test func HFlow_mixedZeroAndNormal() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let items: [TestSubview] = [3 × 2, TestSubview(size: .zero), 3 × 2]
        let size = sut.sizeThatFits(proposal: 100 × 100, subviews: items)
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    // MARK: - Justified Edge Cases

    @Test func HFlow_justified_withLineBreak() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, lineBreakSubview(), 3 × 1, 3 × 1], in: 10 × 2)
        // The zero-size LineBreak marker on the second line is excluded from
        // justification, so the two visible items flush to the row's edges.
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                |XXX    XXX|
                +----------+
                """
        )
    }

    @Test func HFlow_justified_allOnOneLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([2 × 1, 2 × 1, 2 × 1], in: 10 × 1)
        #expect(
            render(result) == """
                +----------+
                |XX  XX  XX|
                +----------+
                """
        )
    }

    @Test func VFlow_justified_sizeThatFits_multipleItems() {
        // Verifies justified VFlow reports the full proposed height as its size
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true)
        let size = sut.sizeThatFits(proposal: 1 × 10, subviews: [1 × 2, 1 × 2, 1 × 2])
        #expect(size.height == 10, "Justified VFlow should expand to fill proposed height")
        #expect(size.width == 1)
    }

    // MARK: - Combined Modifiers

    @Test func HFlow_startInNewLine_withMaxFlex() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let flexItem = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 10 × 1)
        flexItem[FlexibilityLayoutValueKey.self] = .maximum
        flexItem[ShouldStartInNewLineLayoutValueKey.self] = true
        let result = sut.layout([3 × 1, 3 × 1, flexItem], in: 10 × 2)
        #expect(
            render(result) == """
                +----------+
                |XXX XXX   |
                |XXXXXXXXXX|
                +----------+
                """
        )
    }

    @Test func HFlow_multipleConsecutiveLineBreaks() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3 × 1, lineBreakSubview(), lineBreakSubview(), 3 × 1], in: 10 × 2)
        // Multiple line breaks should still result in correct layout
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                |XXX       |
                +----------+
                """
        )
    }

    @Test func HFlow_startInNewLine_onEveryItem() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let items: [TestSubview] = (0 ..< 3).map { _ in newLineSubview(3 × 1) }
        let result = sut.layout(items, in: 10 × 3)
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                |XXX       |
                |XXX       |
                +----------+
                """
        )
    }

    // MARK: - sizeThatFits/placeSubviews Consistency

    @Test func HFlow_sizeThatFits_containsAllPlacements() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 2, verticalSpacing: 3)
        let subviews: [TestSubview] = [10 × 5, 10 × 8, 10 × 5, 10 × 5, 10 × 5]
        let proposal: ProposedViewSize = 35 × 100
        let reportedSize = sut.sizeThatFits(proposal: proposal, subviews: subviews)
        let result = sut.layout(subviews, in: CGSize(width: min(reportedSize.width, 35), height: min(reportedSize.height, 100)))
        for (i, view) in result.subviews.enumerated() {
            guard let placement = view.placement else {
                Issue.record("View \(i) was not placed")
                continue
            }
            #expect(placement.position.x >= 0, "View \(i) x position should be >= 0")
            #expect(placement.position.y >= 0, "View \(i) y position should be >= 0")
            #expect(placement.position.x + placement.size.width <= reportedSize.width + 0.001, "View \(i) should fit within reported width")
            #expect(placement.position.y + placement.size.height <= reportedSize.height + 0.001, "View \(i) should fit within reported height")
        }
    }

    // MARK: - Baseline Alignment

    @Test func HFlow_firstTextBaseline_alignsBaselines() {
        // Items of different heights with baselines at absolute (non-proportional)
        // offsets must be placed so their first baselines coincide, like HStack.
        let sut: FlowLayout = .horizontal(verticalAlignment: .firstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0)
        let small = TestSubview(size: 3 × 4)
        small.firstBaseline = 3
        let large = TestSubview(size: 3 × 10)
        large.firstBaseline = 8
        let result = sut.layout([small, large], in: 100 × 100)
        // ascent = max(3, 8) = 8; small.y = 8 - 3 = 5, large.y = 8 - 8 = 0.
        #expect(result.subviews[0].placement?.position.y == 5, "small should drop so its baseline meets the line baseline")
        #expect(result.subviews[1].placement?.position.y == 0, "large defines the line baseline and stays at the top")
        // Baselines coincide at y = 8.
        let smallBaseline = (result.subviews[0].placement?.position.y ?? 0) + 3
        let largeBaseline = (result.subviews[1].placement?.position.y ?? 0) + 8
        #expect(smallBaseline == largeBaseline)
    }

    @Test func HFlow_firstTextBaseline_reservesDescentBelowBaseline() {
        // The line must be tall enough for the deepest descent below the common
        // baseline, not merely the tallest item.
        let sut: FlowLayout = .horizontal(verticalAlignment: .firstTextBaseline, horizontalSpacing: 0, verticalSpacing: 0)
        let a = TestSubview(size: 3 × 6)
        a.firstBaseline = 5  // descent 1
        let b = TestSubview(size: 3 × 6)
        b.firstBaseline = 2  // descent 4
        let size = sut.sizeThatFits(proposal: 100 × 100, subviews: [a, b])
        // ascent = max(5, 2) = 5; descent = max(1, 4) = 4; height = 9.
        #expect(size.height == 9)
    }

    @Test func HFlow_lastTextBaseline_alignsBaselines() {
        let sut: FlowLayout = .horizontal(verticalAlignment: .lastTextBaseline, horizontalSpacing: 0, verticalSpacing: 0)
        let small = TestSubview(size: 3 × 4)
        small.lastBaseline = 3
        let large = TestSubview(size: 3 × 10)
        large.lastBaseline = 8
        let result = sut.layout([small, large], in: 100 × 100)
        // ascent = max(3, 8) = 8; small.y = 5, large.y = 0.
        #expect(result.subviews[0].placement?.position.y == 5)
        #expect(result.subviews[1].placement?.position.y == 0)
    }

    // MARK: - Non-finite Arithmetic Safety

    @Test func HFlow_infiniteDepthItem_placesWithFiniteCoordinates() {
        // Unbounded cross-axis depth makes the depth-alignment offset ∞/NaN; placements must stay finite.
        let sut: FlowLayout = .horizontal(horizontalAlignment: .leading, verticalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 1)
        let flexHeight = CGSize(width: 3, height: 1) ... CGSize(width: 3, height: inf)
        let result = sut.layout([3 × 1, flexHeight, 3 × 1], in: 10 × 5)
        for (i, view) in result.subviews.enumerated() {
            let position = view.placement?.position
            #expect(position?.x.isFinite == true, "x of view \(i) must be finite")
            #expect(position?.y.isFinite == true, "y of view \(i) must be finite")
        }
    }

    @Test func HFlow_infiniteBreadthItem_centerAligned_placesWithFiniteCoordinates() {
        // Unbounded line breadth makes the breadth-alignment offset ∞-∞=NaN; placement must stay finite.
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0)
        let flexWidth = CGSize(width: 1, height: 1) ... CGSize(width: inf, height: 1)
        flexWidth[FlexibilityLayoutValueKey.self] = .maximum
        let result = sut.layout([flexWidth], in: CGSize(width: inf, height: 1))
        let position = result.subviews[0].placement?.position
        #expect(position?.x.isFinite == true, "x must be finite")
        #expect(position?.y.isFinite == true, "y must be finite")
    }

    @Test func HFlow_justified_unboundedWidth_reportsFiniteNaturalSize() {
        // Justified under an unbounded proposal must fall back to the natural (finite) size.
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let size = sut.sizeThatFits(proposal: ProposedViewSize(width: inf, height: 1), subviews: [3 × 1, 3 × 1, 3 × 1])
        #expect(size.width.isFinite, "Justified width must stay finite under an unbounded proposal")
        #expect(size.width == 11, "Falls back to the natural width: three 3pt items plus two 1pt gaps")
    }

    // MARK: - Unbounded proposal with finite bounds (issue #19)

    @Test func VFlow_unboundedProposal_usesFiniteBoundsHeightForColumnBreaking() {
        // Simulates VFlow inside .frame(maxHeight: 5) in a ScrollView.
        // The frame passes nil height through to placeSubviews unchanged, but allocates
        // bounds.height = 5 after clamping the reported natural height to maxHeight.
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0)
        let subviews: [TestSubview] = repeated(2 × 1, times: 8)
        var cache = sut.makeCache(subviews)
        _ = sut.sizeThatFits(proposal: .unspecified, subviews: subviews, cache: &cache)
        sut.placeSubviews(
            in: CGRect(x: 0, y: 0, width: 2, height: 5),
            proposal: .unspecified,
            subviews: subviews,
            cache: &cache
        )
        // Column 1: items 0–4 at x = 0
        #expect(subviews[0].placement?.position == CGPoint(x: 0, y: 0))
        #expect(subviews[4].placement?.position == CGPoint(x: 0, y: 4))
        // Column 2: items 5–7 start at x = 2 (one column-width across)
        #expect(subviews[5].placement?.position == CGPoint(x: 2, y: 0))
        #expect(subviews[7].placement?.position == CGPoint(x: 2, y: 2))
    }

    @Test func HFlow_unboundedProposal_usesFiniteBoundsWidthForRowBreaking() {
        // Simulates HFlow inside .frame(maxWidth: 5) in a ScrollView.
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let subviews: [TestSubview] = repeated(1 × 2, times: 8)
        var cache = sut.makeCache(subviews)
        _ = sut.sizeThatFits(proposal: .unspecified, subviews: subviews, cache: &cache)
        sut.placeSubviews(
            in: CGRect(x: 0, y: 0, width: 5, height: 2),
            proposal: .unspecified,
            subviews: subviews,
            cache: &cache
        )
        // Row 1: items 0–4 at y = 0
        #expect(subviews[0].placement?.position == CGPoint(x: 0, y: 0))
        #expect(subviews[4].placement?.position == CGPoint(x: 4, y: 0))
        // Row 2: items 5–7 start at y = 2 (one row-height down)
        #expect(subviews[5].placement?.position == CGPoint(x: 0, y: 2))
        #expect(subviews[7].placement?.position == CGPoint(x: 2, y: 2))
    }
}

private func lineBreakSubview() -> TestSubview {
    let sub = TestSubview(size: .zero)
    sub[IsLineBreakLayoutValueKey.self] = true
    return sub
}

private func newLineSubview(_ size: CGSize) -> TestSubview {
    let sub = TestSubview(size: size)
    sub[ShouldStartInNewLineLayoutValueKey.self] = true
    return sub
}
