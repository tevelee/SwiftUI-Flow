import SwiftUI
import XCTest
@testable import Flow

final class FlexibilityTests: XCTestCase {
    func test_HFlow_twoNatural_shareLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1×1...6×1, 1×1...6×1], in: 6×1)
        XCTAssertEqual(render(result), """
        +------+
        |XXXXXX|
        +------+
        """)
    }

    func test_HFlow_naturalAndMinimum_sameLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([1×1...5×1, (1×1...5×1).flexibility(.minimum)], in: 7×1)
        XCTAssertEqual(render(result), """
        +-------+
        |XXXXX X|
        +-------+
        """)
    }

    func test_HFlow_maximum_pushesToOwnLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3×1, (1×1...10×1).flexibility(.maximum), 3×1], in: 10×3)
        XCTAssertEqual(render(result), """
        +----------+
        |XXX       |
        |XXXXXXXXXX|
        |XXX       |
        +----------+
        """)
    }

    func test_HFlow_twoMaximum_separateLines() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([
            (1×1...10×1).flexibility(.maximum),
            (1×1...10×1).flexibility(.maximum)
        ], in: 10×2)
        XCTAssertEqual(render(result), """
        +----------+
        |XXXXXXXXXX|
        |XXXXXXXXXX|
        +----------+
        """)
    }

    func test_HFlow_flexWithHigherPriority() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let sub1 = TestSubview(minSize: 1×1, idealSize: 1×1, maxSize: 5×1)
        let sub2 = TestSubview(minSize: 1×1, idealSize: 1×1, maxSize: 5×1)
        sub2.priority = 2
        let result = sut.layout([sub1, sub2], in: 7×1)
        XCTAssertEqual(render(result), """
        +-------+
        |X XXXXX|
        +-------+
        """)
    }

    func test_VFlow_flexible_natural() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1×1...1×5, 1×1...1×5], in: 1×6)
        XCTAssertEqual(render(result), """
        +-+
        |X|
        |X|
        |X|
        |X|
        |X|
        |X|
        +-+
        """)
    }

    func test_VFlow_flexible_maximum() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1)
        let result = sut.layout([1×1, (1×1...1×8).flexibility(.maximum), 1×1], in: 3×8)
        XCTAssertEqual(render(result), """
        +---+
        |XXX|
        | X |
        | X |
        | X |
        | X |
        | X |
        | X |
        | X |
        +---+
        """)
    }

    func test_HFlow_distributed_withFlex() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)
        let result = sut.layout([3×1, 3×1...6×1, 3×1], in: 12×1)
        XCTAssertEqual(render(result), """
        +------------+
        |XXX XXXX XXX|
        +------------+
        """)
    }

    func test_HFlow_justified_withFlex() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3×1, 3×1...6×1, 2×1], in: 9×2)
        XCTAssertEqual(render(result), """
        +---------+
        |XXX XXX X|
        |XX       |
        +---------+
        """)
    }

    func test_HFlow_justified_singleItemLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3×1, 3×1, 8×1], in: 8×2)
        XCTAssertEqual(render(result), """
        +--------+
        |XXX  XXX|
        |XXXXXXXX|
        +--------+
        """)
    }
}
