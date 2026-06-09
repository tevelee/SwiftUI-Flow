import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.snapshot))
struct LineBreakSnapshots {
    @Test func lineBreakView_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let lb = TestSubview(size: .zero)
        lb[IsLineBreakLayoutValueKey.self] = true
        let result = sut.layout([3 × 1, lb, 3 × 1], in: 10 × 2)
        assertLayoutRendering(result) {
            """
            +----------+
            |AAA       |
            |CCC       |
            +----------+
            """
        }
    }

    @Test func startInNewLine_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let nl = TestSubview(size: 3 × 1)
        nl[ShouldStartInNewLineLayoutValueKey.self] = true
        let result = sut.layout([3 × 1, 3 × 1, nl], in: 10 × 2)
        assertLayoutRendering(result) {
            """
            +----------+
            |AAA BBB   |
            |CCC       |
            +----------+
            """
        }
    }
}
