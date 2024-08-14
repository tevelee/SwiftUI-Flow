import SwiftUI
import XCTest
@testable import Flow

final class FlowTests: XCTestCase {
    func test_HFlow_size_singleElement() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [50×50])

        // Then
        XCTAssertEqual(size, 50×50)
    }

    func test_HFlow_size_multipleElements() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: 130×130, subviews: repeated(50×50, times: 3))

        // Then
        XCTAssertEqual(size, 110×120)
    }

    func test_HFlow_size_justifiedSpaces() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 0, lineSpacing: 0, justification: .stretchSpaces)

        // When
        let size = sut.sizeThatFits(proposal: 1000×1000, subviews: [50×50, 50×50])

        // Then
        XCTAssertEqual(size, 1000×50)
    }

    func test_HFlow_size_justifiedItems() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 0, lineSpacing: 0, justification: .stretchItems)

        // When
        let size = sut.sizeThatFits(proposal: 1000×1000, subviews: [50×1...100×1])

        // Then
        XCTAssertEqual(size, 100×1)
    }

    func test_HFlow_layout_top() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .top, itemSpacing: 1, lineSpacing: 1)
        
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

    func test_HFlow_layout_center() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 1)

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
        let sut: FlowLayout = .horizontal(alignment: .bottom, itemSpacing: 1, lineSpacing: 1)

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
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0)

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
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, distributeItemsEvenly: true)

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

    func test_HFlow_justifiedSpaces_rigid() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchSpaces)

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

    func test_HFlow_justifiedSpaces_flexible() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchSpaces)

        // When
        let result = sut.layout([3×1, 3×1...inf×1, 2×1], in: 9×2)

        // Then
        XCTAssertEqual(render(result), """
        +---------+
        |XXX   XXX|
        |XX       |
        +---------+
        """)
    }

    func test_HFlow_justifiedItems_rigid() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchItems)

        // When
        let result = sut.layout([3×1, 3×1, 2×1], in: 9×2)

        // Then
        XCTAssertEqual(render(result), """
        +---------+
        |XXX XXX  |
        |XX       |
        +---------+
        """)
    }

    func test_HFlow_justifiedItems_flexible() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchItems)

        // When
        let result = sut.layout([3×1...4×1, 3×1...inf×1, 2×1...5×1], in: 9×2)

        // Then
        XCTAssertEqual(render(result), """
        +---------+
        |XXXX XXXX|
        |XXXXX    |
        +---------+
        """)
    }

    func test_HFlow_justifiedItemsAndSpaces_rigid() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchItemsAndSpaces)

        // When
        let result = sut.layout([1×1, 4×1, 3×1, 2×1, 2×1, 3×1], in: 12×2)

        // Then
        XCTAssertEqual(render(result), """
        +------------+
        |X  XXXX  XXX|
        |XX  XX   XXX|
        +------------+
        """)
    }

    func test_HFlow_justifiedItemsAndSpaces_flexible() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchItemsAndSpaces)

        // When
        let result = sut.layout([1×1, 2×1...5×1, 1×1...inf×1, 2×1, 5×1...inf×1, 5×1...inf×1], in: 13×2)

        // Then
        XCTAssertEqual(render(result), """
        +-------------+
        |X XXXX XXX XX|
        |XXXXXX XXXXXX|
        +-------------+
        """)
    }

    func test_HFlow_justifiedItemsAndSpaces_strethBoth() throws {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0, justification: .stretchItemsAndSpaces)

        // When
        let result = sut.layout([4×1...5×1, 4×1...5×1, 4×1...5×1, 4×1...5×1, 4×1...5×1], in: 15×2)

        // Then
        XCTAssertEqual(render(result), """
        +---------------+
        |XXXX XXXX XXXXX|
        |XXXXX     XXXXX|
        +---------------+
        """)
    }

    func test_VFlow_size_singleElement() throws {
        // Given
        let sut: FlowLayout = .vertical(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: 100×100, subviews: [50×50])

        // Then
        XCTAssertEqual(size, 50×50)
    }

    func test_VFlow_size_multipleElements() throws {
        // Given
        let sut: FlowLayout = .vertical(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: 130×130, subviews: repeated(50×50, times: 3))

        // Then
        XCTAssertEqual(size, 120×110)
    }

    func test_VFlow_layout_leading() {
        // Given
        let sut: FlowLayout = .vertical(alignment: .leading, itemSpacing: 1, lineSpacing: 1)

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
        let sut: FlowLayout = .vertical(alignment: .center, itemSpacing: 1, lineSpacing: 1)

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
        let sut: FlowLayout = .vertical(alignment: .trailing, itemSpacing: 1, lineSpacing: 1)

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
        let sut: FlowLayout = .vertical(alignment: .center, itemSpacing: 0, lineSpacing: 0)

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
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0)

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
}
