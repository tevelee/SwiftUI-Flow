import XCTest
@testable import Flow

final class LineBreakingTests: XCTestCase {
    func test_flow() throws {
        // Given
        let sut = FlowLineBreaker()

        // When
        let breakpoints = sut.wrapItemsToLines(
            items: [
                .init(size: .rigid(10), spacing: 10),
                .init(size: .rigid(20), spacing: 10),
                .init(size: .rigid(30), spacing: 10),
                .init(size: .rigid(40), spacing: 10),
                .init(size: .rigid(20), spacing: 10),
                .init(size: .rigid(30), spacing: 10)
            ],
            in: 80
        )

        // Then
        XCTAssertEqual(breakpoints, [
            [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 30, leadingSpace: 10)],
            [.init(index: 3, size: 40, leadingSpace: 0), .init(index: 4, size: 20, leadingSpace: 10)],
            [.init(index: 5, size: 30, leadingSpace: 0)]
        ])
    }

    func test_knuth_plass() throws {
        // Given
        let sut = KnuthPlassLineBreaker()

        // When
        let breakpoints = sut.wrapItemsToLines(
            items: [
                .init(size: .rigid(10), spacing: 10),
                .init(size: .rigid(20), spacing: 10),
                .init(size: .rigid(30), spacing: 10),
                .init(size: .rigid(40), spacing: 10),
                .init(size: .rigid(20), spacing: 10),
                .init(size: .rigid(30), spacing: 10)
            ],
            in: 80
        )

        // Then
        XCTAssertEqual(breakpoints, [
            [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 30, leadingSpace: 10)],
            [.init(index: 3, size: 40, leadingSpace: 0)],
            [.init(index: 4, size: 20, leadingSpace: 0), .init(index: 5, size: 30, leadingSpace: 10)]
        ])
    }
}

private extension ClosedRange {
    static func rigid(_ value: Bound) -> Self {
        value ... value
    }
}
