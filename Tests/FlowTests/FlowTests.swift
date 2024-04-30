import SwiftUI
import XCTest
@testable import Flow

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
final class FlowTests: XCTestCase {
    func test_HFlow_size_singleElement() throws {
        // Given
        let views = [
            TestSubview(width: 50, height: 50)
        ]
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: ProposedViewSize(width: 100, height: 100), subviews: views)

        // Then
        XCTAssertEqual(size, CGSize(width: 50, height: 50))
    }

    func test_HFlow_size_multipleElements() throws {
        // Given
        let views = [
            TestSubview(width: 50, height: 50),
            TestSubview(width: 50, height: 50),
            TestSubview(width: 50, height: 50)
        ]
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        let size = sut.sizeThatFits(proposal: ProposedViewSize(width: 130, height: 130), subviews: views)

        // Then
        XCTAssertEqual(size, CGSize(width: 110, height: 120))
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

    func test_HFlow_layout() {
        // Given
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 1, lineSpacing: 0)

        // When
        let result = sut.layout(Array(repeating: 1×1, count: 15), in: 11×3)

        // Then
        XCTAssertEqual(render(result), """
        +-----------+
        |X X X X X X|
        |X X X X X X|
        |X X X      |
        +-----------+
        """)
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

    func test_VFlow_layout() {
        // Given
        let sut: FlowLayout = .vertical(alignment: .center, itemSpacing: 0, lineSpacing: 0)

        // When
        let result = sut.layout(Array(repeating: 1×1, count: 17), in: 6×3)

        // Then
        XCTAssertEqual(render(result), """
        +------+
        |XXXXXX|
        |XXXXXX|
        |XXXXX |
        +------+
        """)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension FlowLayout {
    func layout(_ views: [CGSize], in bounds: CGSize) -> (subviews: [TestSubview], size: CGSize) {
        let subviews = views.map { TestSubview(width: $0.width, height: $0.height) }
        let size = sizeThatFits(
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height),
            subviews: subviews
        )
        placeSubviews(
            in: CGRect(origin: .zero, size: bounds),
            proposal: ProposedViewSize(width: size.width, height: size.height),
            subviews: subviews
        )
        return (subviews, bounds)
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private func render(_ layout: (subviews: [TestSubview], size: CGSize), border: Bool = true) -> String {
    struct Point: Hashable {
        let x, y: Int
    }

    var positions: Set<Point> = []
    for view in layout.subviews {
        if let point = view.placement {
            for y in Int(point.y) ..< Int(point.y + view.size.height) {
                for x in Int(point.x) ..< Int(point.x + view.size.width) {
                    positions.insert(Point(x: x, y: y))
                }
            }
        }
    }
    let width = Int(layout.size.width)
    let height = Int(layout.size.height)
    var result = ""
    if border {
        result += "+" + String(repeating: "-", count: width) + "+\n"
    }
    for y in 0 ... height - 1 {
        if border {
            result += "|"
        }
        for x in 0 ... width - 1 {
            result += positions.contains(Point(x: x, y: y)) ? "X" : " "
        }
        if border {
            result += "|"
        } else {
            result = result.trimmingCharacters(in: .whitespaces)
        }
        result += "\n"
    }
    if border {
        result += "+" + String(repeating: "-", count: width) + "+\n"
    }
    return result.trimmingCharacters(in: .newlines)
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private final class TestSubview: Subview, CustomStringConvertible {
    var spacing = ViewSpacing()
    var placement: CGPoint?
    let size: CGSize

    init(width: CGFloat, height: CGFloat) {
        size = .init(width: width, height: height)
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        size
    }

    func dimensions(_ proposal: ProposedViewSize) -> Dimensions {
        TestDimensions(size: size)
    }

    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize) {
        placement = position
    }

    var description: String {
        "origin: \((placement?.x).map { "\($0)" } ?? "nil")×\((placement?.y).map { "\($0)" } ?? "nil"), size: \(size.width)×\(size.height)"
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension [TestSubview]: Subviews {}

private struct TestDimensions: Dimensions {
    let size: CGSize

    subscript(guide: HorizontalAlignment) -> CGFloat {
        switch guide {
            case .center: return 0.5 * size.width
            case .trailing: return size.width
            default: return 0
        }
    }

    subscript(guide: VerticalAlignment) -> CGFloat {
        switch guide {
            case .center: return 0.5 * size.height
            case .bottom: return size.height
            default: return 0
        }
    }
}

infix operator ×: MultiplicationPrecedence
private func × (lhs: CGFloat, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs, height: rhs)
}
