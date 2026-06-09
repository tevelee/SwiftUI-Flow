import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.snapshot))
struct SpacingSnapshots {
    @Test func HFlow_zeroSpacing() {
        assertHFlowSpacing(0) {
            """
            +----------+
            |AABBCCDDEE|
            |FFGGHH    |
            +----------+
            """
        }
    }

    @Test func HFlow_onePointSpacing() {
        assertHFlowSpacing(1) {
            """
            +--------+
            |AA BB CC|
            |        |
            |DD EE FF|
            |        |
            |GG HH   |
            +--------+
            """
        }
    }

    @Test func HFlow_threePointSpacing() {
        assertHFlowSpacing(3) {
            """
            +-------+
            |AA   BB|
            |       |
            |       |
            |       |
            |CC   DD|
            |       |
            |       |
            |       |
            |EE   FF|
            |       |
            |       |
            |       |
            |GG   HH|
            +-------+
            """
        }
    }
}

private func assertHFlowSpacing(
    _ spacing: CGFloat,
    matches expected: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let sut: FlowLayout = .horizontal(horizontalSpacing: spacing, verticalSpacing: spacing)
    let subviews = repeated(TestSubview(size: CGSize(width: 2, height: 1)), times: 8)
    let size = sut.sizeThatFits(
        proposal: ProposedViewSize(width: 10, height: 100),
        subviews: subviews
    )
    let result = sut.layout(subviews, in: size)
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
