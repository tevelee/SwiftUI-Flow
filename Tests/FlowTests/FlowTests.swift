import SwiftUI
import Testing
@testable import Flow

@Suite
struct FlowTests {
    @Test func HFlow_size_singleElement() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 10, verticalSpacing: 20)
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [50×50])
        #expect(size == (50×50 as CGSize))
    }

    @Test func HFlow_size_multipleElements() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 10, verticalSpacing: 20)
        let size = sut.sizeThatFits(proposal: 130×130, subviews: repeated(50×50, times: 3))
        #expect(size == (110×120 as CGSize))
    }

    @Test func HFlow_size_justified() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0, justified: true)
        let size = sut.sizeThatFits(proposal: 1000×1000, subviews: [50×50, 50×50])
        #expect(size == (1000×50 as CGSize))
    }

    @Test func HFlow_layout_top() {
        let sut: FlowLayout = .horizontal(verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)
        #expect(render(result) == """
        +--------------------+
        |XXXXX XXXXX XXXXX   |
        |      XXXXX         |
        |      XXXXX         |
        |                    |
        |XXXXX               |
        |                    |
        +--------------------+
        """)
    }

    @Test func HFlow_layout_top_and_leading() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)
        #expect(render(result) == """
        +--------------------+
        |XXXXX XXXXX XXXXX   |
        |      XXXXX         |
        |      XXXXX         |
        |                    |
        |XXXXX               |
        |                    |
        +--------------------+
        """)
    }

    @Test func HFlow_layout_top_and_center() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)
        #expect(render(result) == """
        +--------------------+
        |XXXXX XXXXX XXXXX   |
        |      XXXXX         |
        |      XXXXX         |
        |                    |
        |      XXXXX         |
        |                    |
        +--------------------+
        """)
    }

    @Test func HFlow_layout_top_and_trailing() {
        let sut: FlowLayout = .horizontal(horizontalAlignment: .trailing, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)
        #expect(render(result) == """
        +--------------------+
        |XXXXX XXXXX XXXXX   |
        |      XXXXX         |
        |      XXXXX         |
        |                    |
        |            XXXXX   |
        |                    |
        +--------------------+
        """)
    }

    @Test func HFlow_layout_center() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)
        #expect(render(result) == """
        +--------------------+
        |      XXXXX         |
        |XXXXX XXXXX XXXXX   |
        |      XXXXX         |
        |                    |
        |XXXXX               |
        |                    |
        +--------------------+
        """)
    }

    @Test func HFlow_layout_bottom() {
        let sut: FlowLayout = .horizontal(verticalAlignment: .bottom, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)
        #expect(render(result) == """
        +--------------------+
        |      XXXXX         |
        |      XXXXX         |
        |XXXXX XXXXX XXXXX   |
        |                    |
        |XXXXX               |
        |                    |
        +--------------------+
        """)
    }

    @Test func HFlow_default() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout(repeated(1×1, times: 15), in: 11×3)
        #expect(render(result) == """
        +-----------+
        |X X X X X X|
        |X X X X X X|
        |X X X      |
        +-----------+
        """)
    }

    @Test func HFlow_distributed() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)
        let result = sut.layout(repeated(1×1, times: 13), in: 11×3)
        #expect(render(result) == """
        +-----------+
        |X X X X X  |
        |X X X X    |
        |X X X X    |
        +-----------+
        """)
    }

    @Test func HFlow_justified_rigid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3×1, 3×1, 2×1], in: 9×2)
        #expect(render(result) == """
        +---------+
        |XXX   XXX|
        |XX       |
        +---------+
        """)
    }

    @Test func HFlow_justified_flexible() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3×1, 3×1...inf×1, 2×1], in: 9×2)
        #expect(render(result) == """
        +---------+
        |XXX XXXXX|
        |XX       |
        +---------+
        """)
    }

    @Test func VFlow_size_singleElement() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 20, verticalSpacing: 10)
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [50×50])
        #expect(size == (50×50 as CGSize))
    }

    @Test func VFlow_size_multipleElements() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 20, verticalSpacing: 10)
        let size = sut.sizeThatFits(proposal: 130×130, subviews: repeated(50×50, times: 3))
        #expect(size == (120×110 as CGSize))
    }

    @Test func VFlow_layout_leading() {
        let sut: FlowLayout = .vertical(horizontalAlignment: .leading, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([1×1, 3×1, 1×1, 1×1, 1×1], in: 5×5)
        #expect(render(result) == """
        +-----+
        |X   X|
        |     |
        |XXX X|
        |     |
        |X    |
        +-----+
        """)
    }

    @Test func VFlow_layout_center() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([1×1, 3×1, 1×1, 1×1, 1×1], in: 5×5)
        #expect(render(result) == """
        +-----+
        | X  X|
        |     |
        |XXX X|
        |     |
        | X   |
        +-----+
        """)
    }

    @Test func VFlow_layout_trailing() {
        let sut: FlowLayout = .vertical(horizontalAlignment: .trailing, horizontalSpacing: 1, verticalSpacing: 1)
        let result = sut.layout([1×1, 3×1, 1×1, 1×1, 1×1], in: 5×5)
        #expect(render(result) == """
        +-----+
        |  X X|
        |     |
        |XXX X|
        |     |
        |  X  |
        +-----+
        """)
    }

    @Test func VFlow_default() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout(repeated(1×1, times: 16), in: 6×3)
        #expect(render(result) == """
        +------+
        |XXXXXX|
        |XXXXX |
        |XXXXX |
        +------+
        """)
    }

    @Test func HFlow_text() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([WrappingText(size: 6×1), 1×1, 1×1, 1×1], in: 5×3)
        #expect(render(result) == """
        +-----+
        |XXXXX|
        |XXXXX|
        |X X X|
        +-----+
        """)
    }

    @Test func HFlow_flexible() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([1×1, 1×1, 1×1...10×1, 1×1, 1×1], in: 8×2)
        #expect(render(result) == """
        +--------+
        |X X XX X|
        |X       |
        +--------+
        """)
    }

    @Test func HFlow_flexible_minimum() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([1×1, 1×1, (1×1...10×1).flexibility(.minimum), 1×1, 1×1], in: 8×2)
        #expect(render(result) == """
        +--------+
        |X X X X |
        |X       |
        +--------+
        """)
    }

    @Test func HFlow_flexible_natural() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([1×1, 1×1, (1×1...10×1).flexibility(.natural), 1×1, 1×1], in: 8×2)
        #expect(render(result) == """
        +--------+
        |X X XX X|
        |X       |
        +--------+
        """)
    }

    @Test func HFlow_flexible_maximum() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([1×1, 1×1, (1×1...10×1).flexibility(.maximum), 1×1, 1×1], in: 8×3)
        #expect(render(result) == """
        +--------+
        |X X     |
        |XXXXXXXX|
        |X X     |
        +--------+
        """)
    }
}
