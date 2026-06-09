import SwiftUI
import Testing

@testable import Flow

enum FlexCase {
    case minimum, natural, maximum

    var behavior: FlexibilityBehavior {
        switch self {
            case .minimum: .minimum
            case .natural: .natural
            case .maximum: .maximum
        }
    }
}

@Suite(.tags(.snapshot))
struct FlexibilitySnapshots {
    @Test func HFlow_minimumFlexibility() {
        assertHFlowFlexibility(.minimum) {
            """
            +--------+
            |A B C D |
            |E       |
            |        |
            +--------+
            """
        }
    }

    @Test func HFlow_naturalFlexibility() {
        assertHFlowFlexibility(.natural) {
            """
            +--------+
            |A B CC D|
            |E       |
            |        |
            +--------+
            """
        }
    }

    @Test func HFlow_maximumFlexibility() {
        assertHFlowFlexibility(.maximum) {
            """
            +--------+
            |A B     |
            |CCCCCCCC|
            |D E     |
            +--------+
            """
        }
    }

    @Test func twoFlexible_shareLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1 × 1 ... 6 × 1, 1 × 1 ... 6 × 1], in: 6 × 1)
        assertLayoutRendering(result) {
            """
            +------+
            |AAABBB|
            +------+
            """
        }
    }

    @Test func flexWithPriority() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let sub1 = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 5 × 1)
        let sub2 = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 5 × 1)
        sub2.priority = 2
        let result = sut.layout([sub1, sub2], in: 7 × 1)
        assertLayoutRendering(result) {
            """
            +-------+
            |A BBBBB|
            +-------+
            """
        }
    }
}

private func assertHFlowFlexibility(
    _ flex: FlexCase,
    matches expected: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
    let flexItem = (1 × 1 ... 10 × 1).flexibility(flex.behavior)
    let subviews: [TestSubview] = [1 × 1, 1 × 1, flexItem, 1 × 1, 1 × 1]
    let result = sut.layout(subviews, in: CGSize(width: 8, height: 3))
    assertLayoutRendering(
        result,
        matches: expected,
        fileID: fileID,
        filePath: filePath,
        function: function,
        line: line,
        column: column
    )
}
