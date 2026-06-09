import SwiftUI
import Testing

@testable import Flow

// MARK: - HFlow Alignment Snapshots

@Suite(.tags(.snapshot))
struct HFlowAlignmentSnapshots {
    @Test func HFlow_leadingTopAlignment() {
        assertHFlowAlignment(.leading, .top) {
            """
            +--------------------+
            |AAAAA BBBBB CCCCC   |
            |      BBBBB         |
            |      BBBBB         |
            |                    |
            |DDDDD               |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_leadingCenterAlignment() {
        assertHFlowAlignment(.leading, .center) {
            """
            +--------------------+
            |      BBBBB         |
            |AAAAA BBBBB CCCCC   |
            |      BBBBB         |
            |                    |
            |DDDDD               |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_leadingBottomAlignment() {
        assertHFlowAlignment(.leading, .bottom) {
            """
            +--------------------+
            |      BBBBB         |
            |      BBBBB         |
            |AAAAA BBBBB CCCCC   |
            |                    |
            |DDDDD               |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_centerTopAlignment() {
        assertHFlowAlignment(.center, .top) {
            """
            +--------------------+
            |AAAAA BBBBB CCCCC   |
            |      BBBBB         |
            |      BBBBB         |
            |                    |
            |      DDDDD         |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_centerCenterAlignment() {
        assertHFlowAlignment(.center, .center) {
            """
            +--------------------+
            |      BBBBB         |
            |AAAAA BBBBB CCCCC   |
            |      BBBBB         |
            |                    |
            |      DDDDD         |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_centerBottomAlignment() {
        assertHFlowAlignment(.center, .bottom) {
            """
            +--------------------+
            |      BBBBB         |
            |      BBBBB         |
            |AAAAA BBBBB CCCCC   |
            |                    |
            |      DDDDD         |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_trailingTopAlignment() {
        assertHFlowAlignment(.trailing, .top) {
            """
            +--------------------+
            |AAAAA BBBBB CCCCC   |
            |      BBBBB         |
            |      BBBBB         |
            |                    |
            |            DDDDD   |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_trailingCenterAlignment() {
        assertHFlowAlignment(.trailing, .center) {
            """
            +--------------------+
            |      BBBBB         |
            |AAAAA BBBBB CCCCC   |
            |      BBBBB         |
            |                    |
            |            DDDDD   |
            |                    |
            +--------------------+
            """
        }
    }

    @Test func HFlow_trailingBottomAlignment() {
        assertHFlowAlignment(.trailing, .bottom) {
            """
            +--------------------+
            |      BBBBB         |
            |      BBBBB         |
            |AAAAA BBBBB CCCCC   |
            |                    |
            |            DDDDD   |
            |                    |
            +--------------------+
            """
        }
    }
}

// MARK: - VFlow Alignment Snapshots

@Suite(.tags(.snapshot))
struct VFlowAlignmentSnapshots {
    @Test func VFlow_leadingAlignment() {
        assertVFlowAlignment(.leading) {
            """
            +-----+
            |A   D|
            |     |
            |BBB E|
            |     |
            |C    |
            +-----+
            """
        }
    }

    @Test func VFlow_centerAlignment() {
        assertVFlowAlignment(.center) {
            """
            +-----+
            | A  D|
            |     |
            |BBB E|
            |     |
            | C   |
            +-----+
            """
        }
    }

    @Test func VFlow_trailingAlignment() {
        assertVFlowAlignment(.trailing) {
            """
            +-----+
            |  A D|
            |     |
            |BBB E|
            |     |
            |  C  |
            +-----+
            """
        }
    }
}

private func assertHFlowAlignment(
    _ horizontalAlignment: HorizontalAlignment,
    _ verticalAlignment: VerticalAlignment,
    matches expected: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let sut: FlowLayout = .horizontal(
        horizontalAlignment: horizontalAlignment,
        verticalAlignment: verticalAlignment,
        horizontalSpacing: 1,
        verticalSpacing: 1
    )
    let subviews: [TestSubview] = [
        TestSubview(size: CGSize(width: 5, height: 1)),
        TestSubview(size: CGSize(width: 5, height: 3)),
        TestSubview(size: CGSize(width: 5, height: 1)),
        TestSubview(size: CGSize(width: 5, height: 1)),
    ]
    let result = sut.layout(subviews, in: CGSize(width: 20, height: 6))
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

private func assertVFlowAlignment(
    _ horizontalAlignment: HorizontalAlignment,
    matches expected: (() -> String)? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    let sut: FlowLayout = .vertical(
        horizontalAlignment: horizontalAlignment,
        horizontalSpacing: 1,
        verticalSpacing: 1
    )
    let subviews: [TestSubview] = [
        TestSubview(size: CGSize(width: 1, height: 1)),
        TestSubview(size: CGSize(width: 3, height: 1)),
        TestSubview(size: CGSize(width: 1, height: 1)),
        TestSubview(size: CGSize(width: 1, height: 1)),
        TestSubview(size: CGSize(width: 1, height: 1)),
    ]
    let result = sut.layout(subviews, in: CGSize(width: 5, height: 5))
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
