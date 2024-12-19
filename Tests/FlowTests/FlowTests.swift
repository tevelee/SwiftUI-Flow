import SwiftUI
import XCTest
@testable import Flow

final class FlowTests: XCTestCase {
    func test_HFlow_size_singleElement() throws {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 10, verticalSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [50×50])

        // Then
        XCTAssertEqual(size, 50×50)
    }

    func test_HFlow_size_multipleElements() throws {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 10, verticalSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: 130×130, subviews: repeated(50×50, times: 3))

        // Then
        XCTAssertEqual(size, 110×120)
    }

    func test_HFlow_size_justified() throws {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0, justified: true)

        // When
        let size = sut.sizeThatFits(proposal: 1000×1000, subviews: [50×50, 50×50])

        // Then
        XCTAssertEqual(size, 1000×50)
    }

    func test_HFlow_layout_top() {
        // Given
        let sut: FlowLayout = .horizontal(verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)

        // Then
        XCTAssertEqual(render(result), """
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

    func test_HFlow_layout_top_and_leading() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalAlignment: .leading, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)

        // Then
        XCTAssertEqual(render(result), """
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

    func test_HFlow_layout_top_and_center() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalAlignment: .center, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)

        // Then
        XCTAssertEqual(render(result), """
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

    func test_HFlow_layout_top_and_trailing() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalAlignment: .trailing, verticalAlignment: .top, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)

        // Then
        XCTAssertEqual(render(result), """
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

    func test_HFlow_layout_center() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)

        // Then
        XCTAssertEqual(render(result), """
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

    func test_HFlow_layout_bottom() {
        // Given
        let sut: FlowLayout = .horizontal(verticalAlignment: .bottom, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([5×1, 5×3, 5×1, 5×1], in: 20×6)

        // Then
        XCTAssertEqual(render(result), """
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

    func test_HFlow_default() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)

        // When
        let result = sut.layout(repeated(1×1, times: 15), in: 11×3)

        // Then
        XCTAssertEqual(render(result), """
        +-----------+
        |X X X X X X|
        |X X X X X X|
        |X X X      |
        +-----------+
        """)
    }

    func test_HFlow_distibuted() throws {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)

        // When
        let result = sut.layout(repeated(1×1, times: 13), in: 11×3)

        // Then
        XCTAssertEqual(render(result), """
        +-----------+
        |X X X X X  |
        |X X X X    |
        |X X X X    |
        +-----------+
        """)
    }

    func test_HFlow_justified_rigid() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)

        // When
        let result = sut.layout([3×1, 3×1, 2×1], in: 9×2)

        // Then
        XCTAssertEqual(render(result), """
        +---------+
        |XXX   XXX|
        |XX       |
        +---------+
        """)
    }

    func test_HFlow_justified_flexible() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)

        // When
        let result = sut.layout([3×1, 3×1...inf×1, 2×1], in: 9×2)

        // Then
        XCTAssertEqual(render(result), """
        +---------+
        |XXX XXXXX|
        |XX       |
        +---------+
        """)
    }

    func test_VFlow_size_singleElement() throws {
        // Given
        let sut: FlowLayout = .vertical(horizontalSpacing: 20, verticalSpacing: 10)

        // When
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [50×50])

        // Then
        XCTAssertEqual(size, 50×50)
    }

    func test_VFlow_size_multipleElements() throws {
        // Given
        let sut: FlowLayout = .vertical(horizontalSpacing: 20, verticalSpacing: 10)

        // When
        let size = sut.sizeThatFits(proposal: 130×130, subviews: repeated(50×50, times: 3))

        // Then
        XCTAssertEqual(size, 120×110)
    }

    func test_VFlow_layout_leading() {
        // Given
        let sut: FlowLayout = .vertical(horizontalAlignment: .leading, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([1×1, 3×1, 1×1, 1×1, 1×1], in: 5×5)

        // Then
        XCTAssertEqual(render(result), """
        +-----+
        |X   X|
        |     |
        |XXX X|
        |     |
        |X    |
        +-----+
        """)
    }
    func test_VFlow_layout_center() {
        // Given
        let sut: FlowLayout = .vertical(horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([1×1, 3×1, 1×1, 1×1, 1×1], in: 5×5)

        // Then
        XCTAssertEqual(render(result), """
        +-----+
        | X  X|
        |     |
        |XXX X|
        |     |
        | X   |
        +-----+
        """)
    }

    func test_VFlow_layout_trailing() {
        // Given
        let sut: FlowLayout = .vertical(horizontalAlignment: .trailing, horizontalSpacing: 1, verticalSpacing: 1)

        // When
        let result = sut.layout([1×1, 3×1, 1×1, 1×1, 1×1], in: 5×5)

        // Then
        XCTAssertEqual(render(result), """
        +-----+
        |  X X|
        |     |
        |XXX X|
        |     |
        |  X  |
        +-----+
        """)
    }

    func test_VFlow_default() {
        // Given
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0)

        // When
        let result = sut.layout(repeated(1×1, times: 16), in: 6×3)

        // Then
        XCTAssertEqual(render(result), """
        +------+
        |XXXXXX|
        |XXXXX |
        |XXXXX |
        +------+
        """)
    }

    func test_HFlow_text() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)

        // When
        let result = sut.layout([WrappingText(size: 6×1), 1×1, 1×1, 1×1], in: 5×3)

        // Then
        XCTAssertEqual(render(result), """
        +-----+
        |XXXXX|
        |XXXXX|
        |X X X|
        +-----+
        """)
    }

    func test_HFlow_flexible() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)

        // When
        let result = sut.layout([1×1, 1×1, 1×1...10×1, 1×1, 1×1], in: 8×2)

        // Then
        XCTAssertEqual(render(result), """
        +--------+
        |X X XX X|
        |X       |
        +--------+
        """)
    }

    func test_HFlow_flexible_minimum() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)

        // When
        let result = sut.layout([1×1, 1×1, (1×1...10×1).flexibility(.minimum), 1×1, 1×1], in: 8×2)

        // Then
        XCTAssertEqual(render(result), """
        +--------+
        |X X X X |
        |X       |
        +--------+
        """)
    }

    func test_HFlow_flexible_natural() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)

        // When
        let result = sut.layout([1×1, 1×1, (1×1...10×1).flexibility(.natural), 1×1, 1×1], in: 8×2)

        // Then
        XCTAssertEqual(render(result), """
        +--------+
        |X X XX X|
        |X       |
        +--------+
        """)
    }

    func test_HFlow_flexible_maximum() {
        // Given
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)

        // When
        let result = sut.layout([1×1, 1×1, (1×1...10×1).flexibility(.maximum), 1×1, 1×1], in: 8×3)

        // Then
        XCTAssertEqual(render(result), """
        +--------+
        |X X     |
        |XXXXXXXX|
        |X X     |
        +--------+
        """)
    }
}
