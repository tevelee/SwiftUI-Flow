import SwiftUI
import Testing

@testable import Flow

@Suite
struct FlexibilityTests {
    @Test func HFlow_twoNatural_shareLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1 × 1 ... 6 × 1, 1 × 1 ... 6 × 1], in: 6 × 1)
        #expect(
            render(result) == """
                +------+
                |XXXXXX|
                +------+
                """
        )
    }

    @Test func HFlow_naturalAndMinimum_sameLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([1 × 1 ... 5 × 1, (1 × 1 ... 5 × 1).flexibility(.minimum)], in: 7 × 1)
        #expect(
            render(result) == """
                +-------+
                |XXXXX X|
                +-------+
                """
        )
    }

    @Test func HFlow_maximum_pushesToOwnLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout([3 × 1, (1 × 1 ... 10 × 1).flexibility(.maximum), 3 × 1], in: 10 × 3)
        #expect(
            render(result) == """
                +----------+
                |XXX       |
                |XXXXXXXXXX|
                |XXX       |
                +----------+
                """
        )
    }

    @Test func HFlow_twoMaximum_separateLines() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let result = sut.layout(
            [
                (1 × 1 ... 10 × 1).flexibility(.maximum),
                (1 × 1 ... 10 × 1).flexibility(.maximum),
            ],
            in: 10 × 2
        )
        #expect(
            render(result) == """
                +----------+
                |XXXXXXXXXX|
                |XXXXXXXXXX|
                +----------+
                """
        )
    }

    @Test func HFlow_flexWithHigherPriority() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let sub1 = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 5 × 1)
        let sub2 = TestSubview(minSize: 1 × 1, idealSize: 1 × 1, maxSize: 5 × 1)
        sub2.priority = 2
        let result = sut.layout([sub1, sub2], in: 7 × 1)
        #expect(
            render(result) == """
                +-------+
                |X XXXXX|
                +-------+
                """
        )
    }

    @Test func VFlow_flexible_natural() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1 × 1 ... 1 × 5, 1 × 1 ... 1 × 5], in: 1 × 6)
        #expect(
            render(result) == """
                +-+
                |X|
                |X|
                |X|
                |X|
                |X|
                |X|
                +-+
                """
        )
    }

    @Test func VFlow_flexible_maximum() {
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1)
        let result = sut.layout([1 × 1, (1 × 1 ... 1 × 8).flexibility(.maximum), 1 × 1], in: 3 × 8)
        #expect(
            render(result) == """
                +---+
                |XXX|
                | X |
                | X |
                | X |
                | X |
                | X |
                | X |
                | X |
                +---+
                """
        )
    }

    @Test func HFlow_distributed_withFlex() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, distributeItemsEvenly: true)
        let result = sut.layout([3 × 1, 3 × 1 ... 6 × 1, 3 × 1], in: 12 × 1)
        #expect(
            render(result) == """
                +------------+
                |XXX XXXX XXX|
                +------------+
                """
        )
    }

    @Test func HFlow_justified_withFlex() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, 3 × 1 ... inf × 1, 2 × 1], in: 9 × 2)
        #expect(
            render(result) == """
                +---------+
                |XXX XXXXX|
                |XX       |
                +---------+
                """
        )
    }

    @Test func HFlow_justified_singleItemLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true)
        let result = sut.layout([3 × 1, 3 × 1, 8 × 1], in: 8 × 2)
        #expect(
            render(result) == """
                +--------+
                |XXX  XXX|
                |XXXXXXXX|
                +--------+
                """
        )
    }

    @Test func VFlow_flexible_minimum() {
        // With minimum flexibility, item2 stays at height 1 even with remaining space in column
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 1)
        let result = sut.layout([1 × 1, 1 × 1, (1 × 1 ... 1 × 5).flexibility(.minimum), 1 × 1, 1 × 1], in: 2 × 8)
        #expect(
            render(result) == """
                +--+
                |XX|
                |  |
                |X |
                |  |
                |X |
                |  |
                |X |
                |  |
                +--+
                """
        )
    }

    // MARK: - Cross-axis (depth) expansion

    @Test func VFlow_infiniteMaxDepth_fillsColumnNaturalWidth() {
        // A 5pt-wide item anchors the column's natural width. An item with infinite max
        // width should expand to fill that width (5pt), not grow without bound.
        let sut: FlowLayout = .vertical(horizontalSpacing: 0, verticalSpacing: 0)
        let fixed: TestSubview = 5 × 1
        let expandable: TestSubview = 1 × 1 ... inf × 1
        _ = sut.layout([fixed, expandable], in: 10 × 2)
        #expect(expandable.placement?.size.width == 5)
    }

    @Test func VFlow_finiteMaxDepth_notConstrained() {
        // An item with a finite max width is not affected — it still inflates the column
        // to its max size (10pt), not the natural column width (5pt).
        let sut: FlowLayout = .vertical(horizontalAlignment: .leading, horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([5 × 1, 1 × 1 ... 10 × 1], in: 10 × 2)
        #expect(
            render(result) == """
                +----------+
                |XXXXX     |
                |XXXXXXXXXX|
                +----------+
                """
        )
    }

    @Test func HFlow_infiniteMaxDepth_fillsRowNaturalHeight() {
        // A 5pt-tall item anchors the row's natural height. An item with infinite max
        // height should expand to fill that height (5pt), not grow without bound.
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let fixed: TestSubview = 1 × 5
        let expandable: TestSubview = 1 × 1 ... 1 × inf
        _ = sut.layout([fixed, expandable], in: 2 × 10)
        #expect(expandable.placement?.size.height == 5)
    }

    @Test func HFlow_finiteMaxDepth_notConstrained() {
        // An item with a finite max height is not affected — it still inflates the row
        // to its max size (10pt), not the natural row height (5pt).
        let sut: FlowLayout = .horizontal(verticalAlignment: .top, horizontalSpacing: 0, verticalSpacing: 0)
        let result = sut.layout([1 × 5, 1 × 1 ... 1 × 10], in: 2 × 10)
        #expect(
            render(result) == """
                +--+
                |XX|
                |XX|
                |XX|
                |XX|
                |XX|
                | X|
                | X|
                | X|
                | X|
                | X|
                +--+
                """
        )
    }
}
