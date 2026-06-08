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

// MARK: - Spacing Snapshots

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

// MARK: - Flexibility Snapshots

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

// MARK: - Justified & Distributed Snapshots

@Suite(.tags(.snapshot))
struct JustifiedDistributedSnapshots {
    @Test func HFlow_justified_rigid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, 3 × 1, 2 × 1], in: 9 × 2)
        assertLayoutRendering(result) {
            """
            +---------+
            |AAA   BBB|
            |CC       |
            +---------+
            """
        }
    }

    @Test func HFlow_justified_flexible() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, 3 × 1 ... inf × 1, 2 × 1], in: 9 × 2)
        assertLayoutRendering(result) {
            """
            +---------+
            |AAA BBBBB|
            |CC       |
            +---------+
            """
        }
    }

    @Test func HFlow_justified_threePerLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let subviews: [TestSubview] = [2 × 1, 2 × 1, 2 × 1, 2 × 1]
        let result = sut.layout(subviews, in: 10 × 2)
        assertLayoutRendering(result) {
            """
            +----------+
            |AA  BB  CC|
            |DD        |
            +----------+
            """
        }
    }

    @Test func HFlow_distributed() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)
        let result = sut.layout(repeated(1 × 1, times: 13), in: 11 × 3)
        assertLayoutRendering(result) {
            """
            +-----------+
            |A B C D E  |
            |F G H I    |
            |J K L M    |
            +-----------+
            """
        }
    }
}

// MARK: - Line Break Snapshots

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

// MARK: - Wrapping Text Snapshots

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

// MARK: - Large Layout Snapshots

@Suite(.tags(.snapshot))
struct LargeLayoutSnapshots {
    @Test func mixedSizes_30items() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let subviews: [TestSubview] = (0 ..< 30).map { i in
            let w = CGFloat(1 + (i % 5))
            let h = CGFloat(1 + (i % 3))
            return TestSubview(size: CGSize(width: w, height: h))
        }
        let size = sut.sizeThatFits(
            proposal: ProposedViewSize(width: 20, height: 100),
            subviews: subviews
        )
        let result = sut.layout(subviews, in: size)
        assertLayoutRendering(result) {
            """
            +-------------------+
            |  BB CCC      EEEEE|
            |A BB CCC DDDD EEEEE|
            |     CCC           |
            |                   |
            |F    HHH IIII      |
            |F GG HHH IIII JJJJJ|
            |F        IIII      |
            |                   |
            |K LL     NNNN OOOOO|
            |K LL MMM NNNN OOOOO|
            |  LL          OOOOO|
            |                   |
            |  QQ RRR      TTTTT|
            |P QQ RRR SSSS TTTTT|
            |     RRR           |
            |                   |
            |U    WWW XXXX      |
            |U VV WWW XXXX YYYYY|
            |U        XXXX      |
            |                   |
            |Z aa     cccc ddddd|
            |Z aa bbb cccc ddddd|
            |  aa          ddddd|
            +-------------------+
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
