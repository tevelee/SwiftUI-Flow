import SwiftUI
import Testing
@testable import Flow

@Suite
struct LayoutEngineTests {
    @Test func HFlow_lineBreak_forcesNewRow() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, lineBreakSubview(), 3×1], in: 10×2)
        #expect(render(result) == """
        +----------+
        |XXX       |
        |XXX       |
        +----------+
        """)
    }

    @Test func HFlow_lineBreak_atStart() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([lineBreakSubview(), 3×1], in: 10×1)
        #expect(render(result) == """
        +----------+
        |XXX       |
        +----------+
        """)
    }

    @Test func HFlow_lineBreak_atEnd() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, lineBreakSubview()], in: 10×1)
        #expect(render(result) == """
        +----------+
        |XXX       |
        +----------+
        """)
    }

    @Test func HFlow_startInNewLine_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, 3×1, newLineSubview(3×1)], in: 10×2)
        #expect(render(result) == """
        +----------+
        |XXX XXX   |
        |XXX       |
        +----------+
        """)
    }

    @Test func HFlow_startInNewLine_first() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([newLineSubview(3×1), 3×1], in: 10×1)
        #expect(render(result) == """
        +----------+
        |XXX XXX   |
        +----------+
        """)
    }

    @Test func HFlow_justified_threeItems() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([2×1, 2×1, 2×1], in: 10×1)
        #expect(render(result) == """
        +----------+
        |XX  XX  XX|
        +----------+
        """)
    }

    @Test func HFlow_justified_singleItem() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([5×1], in: 10×1)
        #expect(render(result) == """
        +----------+
        |XXXXX     |
        +----------+
        """)
    }

    @Test func VFlow_justified_sizeThatFits() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true)
        let size = sut.sizeThatFits(proposal: 1×6, subviews: [1×2, 1×2, 1×2])
        #expect(size.height == 6)
    }

    @Test func VFlow_distributed_sizeThatFits() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true)
        let size = sut.sizeThatFits(proposal: 2×5, subviews: repeated(1×1, times: 5))
        #expect(size.width > 0)
    }

    @Test func HFlow_emptySubviews() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [TestSubview]())
        #expect(size == CGSize.zero)
    }

    @Test func HFlow_singleItem_centered() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, 3×1, 3×1], in: 10×2)
        #expect(render(result) == """
        +----------+
        |XXX XXX   |
        |  XXX     |
        +----------+
        """)
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
