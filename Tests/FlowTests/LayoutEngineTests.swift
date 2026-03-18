import SwiftUI
import XCTest
@testable import Flow

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

final class LayoutEngineTests: XCTestCase {
    func test_HFlow_lineBreak_forcesNewRow() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, lineBreakSubview(), 3×1], in: 10×2)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX       |
        |XXX       |
        +----------+
        """)
    }

    func test_HFlow_lineBreak_atStart() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([lineBreakSubview(), 3×1], in: 10×1)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX       |
        +----------+
        """)
    }

    func test_HFlow_lineBreak_atEnd() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, lineBreakSubview()], in: 10×1)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX       |
        +----------+
        """)
    }

    func test_HFlow_startInNewLine_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, 3×1, newLineSubview(3×1)], in: 10×2)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX XXX   |
        |XXX       |
        +----------+
        """)
    }

    func test_HFlow_startInNewLine_first() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([newLineSubview(3×1), 3×1], in: 10×1)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX XXX   |
        +----------+
        """)
    }

    func test_HFlow_justified_threeItems() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([2×1, 2×1, 2×1], in: 10×1)
        XCTAssertEqual(render(result), """
        +----------+
        |XX  XX  XX|
        +----------+
        """)
    }

    func test_HFlow_justified_singleItem() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([5×1], in: 10×1)
        XCTAssertEqual(render(result), """
        +----------+
        |XXXXX     |
        +----------+
        """)
    }

    func test_VFlow_justified() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0, justified: true)
        let size = sut.sizeThatFits(proposal: 1×6, subviews: [1×2, 1×2, 1×2])
        XCTAssertEqual(size.height, 6)
    }

    func test_VFlow_distributed() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true)
        let size = sut.sizeThatFits(proposal: 2×5, subviews: repeated(1×1, times: 5))
        XCTAssertNotNil(size)
    }

    func test_VFlow_distributed() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1, distributeItemsEvenly: true)
        let result = sut.layout(repeated(1×1, times: 5), in: 2×5)
        XCTAssertNotNil(result.reportedSize)
    }

    func test_HFlow_emptySubviews() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [TestSubview]())
        XCTAssertEqual(size, CGSize.zero)
    }

    func test_HFlow_singleItem_centered() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, 3×1, 3×1], in: 10×2)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX XXX   |
        |  XXX     |
        +----------+
        """)
    }

    func test_HFlow_zeroSizeItems_noAlignmentCrash() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, horizontalSpacing: 0, verticalSpacing: 0)
        let zero1 = TestSubview(size: .zero)
        let zero2 = TestSubview(size: .zero)
        let size = sut.sizeThatFits(
            proposal: ProposedViewSize(width: 100, height: 100),
            subviews: [zero1, zero2]
        )
        XCTAssertEqual(size, CGSize.zero)
    }
}
