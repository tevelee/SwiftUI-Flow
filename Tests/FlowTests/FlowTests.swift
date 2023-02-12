import SwiftUI
import XCTest
@testable import Flow

final class FlowTests: XCTestCase {
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func test_HFlow_placement_centerAlignment() throws {
        // Given
        let views = [
            TestSubview(width: 50, height: 60),
            TestSubview(width: 50, height: 30),
            TestSubview(width: 50, height: 60)
        ]
        let sut: FlowLayout = .horizontal(alignment: .center, itemSpacing: 10, lineSpacing: 20)

        // When
        sut.placeSubviews(in: CGRect(origin: .zero, size: CGSize(width: 150, height: 150)),
                          proposal: ProposedViewSize(width: 120, height: 150),
                          subviews: views)

        // Then
        XCTAssertEqual(views[0].placement, CGPoint(x: 0, y: 0))
        XCTAssertEqual(views[1].placement, CGPoint(x: 60, y: 15))
        XCTAssertEqual(views[2].placement, CGPoint(x: 0, y: 80))
    }
    
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func test_HFlow_placement_topAlignment() throws {
        // Given
        let views = [
            TestSubview(width: 50, height: 30),
            TestSubview(width: 50, height: 50),
            TestSubview(width: 50, height: 30),
            TestSubview(width: 50, height: 60),
        ]
        let sut: FlowLayout = .horizontal(alignment: .top, itemSpacing: 10, lineSpacing: 20)

        // When
        sut.placeSubviews(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)),
                          proposal: ProposedViewSize(width: 120, height: 120),
                          subviews: views)

        // Then
        XCTAssertEqual(views[0].placement, CGPoint(x: 0, y: 0))
        XCTAssertEqual(views[1].placement, CGPoint(x: 60, y: 0))
        XCTAssertEqual(views[2].placement, CGPoint(x: 0, y: 70))
        XCTAssertEqual(views[3].placement, CGPoint(x: 60, y: 70))
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private final class TestSubview: Subview {
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
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension Array: Subviews where Element == TestSubview {}

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
