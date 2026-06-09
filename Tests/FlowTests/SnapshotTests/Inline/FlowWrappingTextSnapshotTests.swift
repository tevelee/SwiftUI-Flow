import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.snapshot))
struct WrappingTextSnapshots {
    @Test func wrappingText_fillsWidth() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([WrappingText(size: 6 × 1), 1 × 1, 1 × 1, 1 × 1], in: 5 × 3)
        assertLayoutRendering(result) {
            """
            +-----+
            |AAAAA|
            |AAAAA|
            |B C D|
            +-----+
            """
        }
    }
}
