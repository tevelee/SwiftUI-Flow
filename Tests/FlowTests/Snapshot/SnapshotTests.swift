import SwiftUI
import Testing
import SnapshotTesting
@testable import Flow

// MARK: - HFlow Alignment Snapshots

@Suite
struct HFlowAlignmentSnapshots {
    @Test(arguments: HorizontalAlignment.allCases, VerticalAlignment.allCases)
    func alignment(_ h: HorizontalAlignment, _ v: VerticalAlignment) {
        let sut: FlowLayout = .horizontal(
            horizontalAlignment: h,
            verticalAlignment: v,
            horizontalSpacing: 1,
            verticalSpacing: 1
        )
        let subviews: [TestSubview] = [
            TestSubview(size: CGSize(width: 5, height: 1)),
            TestSubview(size: CGSize(width: 5, height: 3)),
            TestSubview(size: CGSize(width: 5, height: 1)),
            TestSubview(size: CGSize(width: 5, height: 1))
        ]
        let result = sut.layout(subviews, in: CGSize(width: 20, height: 6))
        assertSnapshot(
            of: labeledRender(result),
            as: .lines,
            named: "\(h.testDescription)_\(v.testDescription)"
        )
    }
}

// MARK: - VFlow Alignment Snapshots

@Suite
struct VFlowAlignmentSnapshots {
    @Test(arguments: HorizontalAlignment.allCases)
    func alignment(_ h: HorizontalAlignment) {
        let sut: FlowLayout = .vertical(
            horizontalAlignment: h,
            horizontalSpacing: 1,
            verticalSpacing: 1
        )
        let subviews: [TestSubview] = [
            TestSubview(size: CGSize(width: 1, height: 1)),
            TestSubview(size: CGSize(width: 3, height: 1)),
            TestSubview(size: CGSize(width: 1, height: 1)),
            TestSubview(size: CGSize(width: 1, height: 1)),
            TestSubview(size: CGSize(width: 1, height: 1))
        ]
        let result = sut.layout(subviews, in: CGSize(width: 5, height: 5))
        assertSnapshot(of: render(result), as: .lines, named: h.testDescription)
    }
}

// MARK: - Spacing Snapshots

@Suite
struct SpacingSnapshots {
    @Test(arguments: [0, 1, 3] as [CGFloat])
    func HFlow_spacing(_ spacing: CGFloat) {
        let sut: FlowLayout = .horizontal(horizontalSpacing: spacing, verticalSpacing: spacing)
        let subviews = repeated(TestSubview(size: CGSize(width: 2, height: 1)), times: 8)
        let size = sut.sizeThatFits(
            proposal: ProposedViewSize(width: 10, height: 100),
            subviews: subviews
        )
        let result = sut.layout(subviews, in: size)
        assertSnapshot(of: render(result), as: .lines, named: "spacing_\(Int(spacing))")
    }
}

// MARK: - Flexibility Snapshots

enum FlexCase: String, CaseIterable, Sendable, CustomTestStringConvertible {
    case minimum, natural, maximum

    var testDescription: String { rawValue }

    var behavior: FlexibilityBehavior {
        switch self {
        case .minimum: .minimum
        case .natural: .natural
        case .maximum: .maximum
        }
    }
}

@Suite
struct FlexibilitySnapshots {
    @Test(arguments: FlexCase.allCases)
    func HFlow_flexibility(_ flex: FlexCase) {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let flexItem = (1×1...10×1).flexibility(flex.behavior)
        let subviews: [TestSubview] = [1×1, 1×1, flexItem, 1×1, 1×1]
        let result = sut.layout(subviews, in: CGSize(width: 8, height: 3))
        assertSnapshot(of: labeledRender(result), as: .lines, named: flex.rawValue)
    }

    @Test func twoFlexible_shareLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1×1...6×1, 1×1...6×1], in: 6×1)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }

    @Test func flexWithPriority() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let sub1 = TestSubview(minSize: 1×1, idealSize: 1×1, maxSize: 5×1)
        let sub2 = TestSubview(minSize: 1×1, idealSize: 1×1, maxSize: 5×1)
        sub2.priority = 2
        let result = sut.layout([sub1, sub2], in: 7×1)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }
}

// MARK: - Justified & Distributed Snapshots

@Suite
struct JustifiedDistributedSnapshots {
    @Test func HFlow_justified_rigid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3×1, 3×1, 2×1], in: 9×2)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }

    @Test func HFlow_justified_flexible() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3×1, 3×1...inf×1, 2×1], in: 9×2)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }

    @Test func HFlow_justified_threePerLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let subviews: [TestSubview] = [2×1, 2×1, 2×1, 2×1]
        let result = sut.layout(subviews, in: 10×2)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }

    @Test func HFlow_distributed() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)
        let result = sut.layout(repeated(1×1, times: 13), in: 11×3)
        assertSnapshot(of: render(result), as: .lines)
    }
}

// MARK: - Line Break Snapshots

@Suite
struct LineBreakSnapshots {
    @Test func lineBreakView_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let lb = TestSubview(size: .zero)
        lb[IsLineBreakLayoutValueKey.self] = true
        let result = sut.layout([3×1, lb, 3×1], in: 10×2)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }

    @Test func startInNewLine_mid() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let nl = TestSubview(size: 3×1)
        nl[ShouldStartInNewLineLayoutValueKey.self] = true
        let result = sut.layout([3×1, 3×1, nl], in: 10×2)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }
}

// MARK: - Wrapping Text Snapshots

@Suite
struct WrappingTextSnapshots {
    @Test func wrappingText_fillsWidth() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([WrappingText(size: 6×1), 1×1, 1×1, 1×1], in: 5×3)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }
}

// MARK: - Large Layout Snapshots

@Suite
struct LargeLayoutSnapshots {
    @Test func mixedSizes_30items() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 1)
        let subviews: [TestSubview] = (0..<30).map { i in
            let w = CGFloat(1 + (i % 5))
            let h = CGFloat(1 + (i % 3))
            return TestSubview(size: CGSize(width: w, height: h))
        }
        let size = sut.sizeThatFits(
            proposal: ProposedViewSize(width: 20, height: 100),
            subviews: subviews
        )
        let result = sut.layout(subviews, in: size)
        assertSnapshot(of: labeledRender(result), as: .lines)
    }
}
