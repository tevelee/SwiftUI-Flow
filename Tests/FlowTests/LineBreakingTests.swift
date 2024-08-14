import XCTest
@testable import Flow

final class LineBreakingTests: XCTestCase {
    func test_flow() throws {
        // Given
        let sut = FlowLineBreaker()

        // When
        let breakpoints = sut.wrapItemsToLines(
            sizes: [10, 20, 30, 40, 20, 30],
            spacings: [0, 10, 10, 10, 10, 10],
            in: 80
        )

        // Then
        XCTAssertEqual(breakpoints, [0, 3, 5, 6])
    }

    func test_knuth_plass() throws {
        // Given
        let sut = KnuthPlassLineBreaker()

        // When
        let breakpoints = sut.wrapItemsToLines(
            sizes: [10, 20, 30, 40, 20, 30],
            spacings: [0, 10, 10, 10, 10, 10],
            in: 80
        )

        // Then
        XCTAssertEqual(breakpoints, [0, 3, 4, 6])
    }
}
