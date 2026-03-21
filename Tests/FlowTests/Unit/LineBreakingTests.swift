import CoreFoundation
import Testing
@testable import Flow

@Suite
struct LineBreakingTests {
    // MARK: - FlowLineBreaker

    @Test func flow_basic() {
        let sut = FlowLineBreaker()
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
        #expect(breakpoints == [
            [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 30, leadingSpace: 10)],
            [.init(index: 3, size: 40, leadingSpace: 0), .init(index: 4, size: 20, leadingSpace: 10)],
            [.init(index: 5, size: 30, leadingSpace: 0)]
        ])
    }

    @Test func flow_emptyInput() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [], in: 100)
        #expect(result == [])
    }

    @Test func flow_singleItem() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(50), spacing: 0)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 50, leadingSpace: 0)]
        ])
    }

    @Test func flow_allFitOnOneLine() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(20), spacing: 0),
            .init(size: .rigid(30), spacing: 10),
            .init(size: .rigid(20), spacing: 10)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 20, leadingSpace: 0), .init(index: 1, size: 30, leadingSpace: 10), .init(index: 2, size: 20, leadingSpace: 10)]
        ])
    }

    @Test func flow_eachItemOwnLine() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(100), spacing: 0),
            .init(size: .rigid(100), spacing: 10),
            .init(size: .rigid(100), spacing: 10)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 100, leadingSpace: 0)],
            [.init(index: 1, size: 100, leadingSpace: 0)],
            [.init(index: 2, size: 100, leadingSpace: 0)]
        ])
    }

    @Test func flow_flexibleItem_expands() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(30), spacing: 0),
            .init(size: 20...60, spacing: 10)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 30, leadingSpace: 0), .init(index: 1, size: 60, leadingSpace: 10)]
        ])
    }

    @Test func flow_lineBreakView() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(20), spacing: 0),
            .init(size: .rigid(0), spacing: 0, isLineBreakView: true),
            .init(size: .rigid(20), spacing: 10)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 20, leadingSpace: 0)],
            [.init(index: 1, size: 0, leadingSpace: 0), .init(index: 2, size: 20, leadingSpace: 0)]
        ])
    }

    @Test func flow_shouldStartInNewLine() {
        let sut = FlowLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(20), spacing: 0),
            .init(size: .rigid(20), spacing: 10),
            .init(size: .rigid(20), spacing: 10, shouldStartInNewLine: true)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 20, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10)],
            [.init(index: 2, size: 20, leadingSpace: 0)]
        ])
    }

    // MARK: - KnuthPlassLineBreaker

    @Test func knuth_plass_basic() {
        let sut = KnuthPlassLineBreaker()
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
        #expect(breakpoints == [
            [.init(index: 0, size: 10, leadingSpace: 0), .init(index: 1, size: 20, leadingSpace: 10), .init(index: 2, size: 30, leadingSpace: 10)],
            [.init(index: 3, size: 40, leadingSpace: 0)],
            [.init(index: 4, size: 20, leadingSpace: 0), .init(index: 5, size: 30, leadingSpace: 10)]
        ])
    }

    @Test func knuth_plass_emptyInput() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [], in: 100)
        #expect(result == [])
    }

    @Test func knuth_plass_singleItem() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(50), spacing: 0)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 50, leadingSpace: 0)]
        ])
    }

    @Test func knuth_plass_flexibleItems_stretchPenalty() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(30), spacing: 0),
            .init(size: 20...60, spacing: 10)
        ], in: 80)
        #expect(result == [
            [.init(index: 0, size: 30, leadingSpace: 0), .init(index: 1, size: 40, leadingSpace: 10)]
        ])
    }

    @Test func knuth_plass_lineBreakView() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(20), spacing: 0),
            .init(size: .rigid(0), spacing: 0, isLineBreakView: true),
            .init(size: .rigid(20), spacing: 10)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 20, leadingSpace: 0)],
            [.init(index: 1, size: 0, leadingSpace: 0), .init(index: 2, size: 20, leadingSpace: 0)]
        ])
    }

    @Test func knuth_plass_shouldStartInNewLine() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(20), spacing: 0),
            .init(size: .rigid(20), spacing: 10, shouldStartInNewLine: true)
        ], in: 100)
        #expect(result == [
            [.init(index: 0, size: 20, leadingSpace: 0)],
            [.init(index: 1, size: 20, leadingSpace: 0)]
        ])
    }

    @Test func knuth_plass_vs_flow_balancedLines() {
        let items: [LineItemInput] = [
            .init(size: .rigid(30), spacing: 0),
            .init(size: .rigid(30), spacing: 10),
            .init(size: .rigid(30), spacing: 10),
            .init(size: .rigid(30), spacing: 10),
            .init(size: .rigid(30), spacing: 10)
        ]

        let flow = FlowLineBreaker().wrapItemsToLines(items: items, in: 80)
        let knuth = KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: 80)

        // Both should produce valid line breaks
        #expect(!flow.isEmpty)
        #expect(!knuth.isEmpty)

        // Knuth-Plass should produce more balanced lines
        func lineWidth(_ line: [LineItemOutput]) -> CGFloat {
            line.reduce(CGFloat(0)) { $0 + $1.size + $1.leadingSpace }
        }
        let flowWidths = flow.map(lineWidth)
        let knuthWidths = knuth.map(lineWidth)

        let flowImbalance = (flowWidths.max() ?? 0) - (flowWidths.min() ?? 0)
        let knuthImbalance = (knuthWidths.max() ?? 0) - (knuthWidths.min() ?? 0)

        #expect(knuthImbalance <= flowImbalance, "Knuth-Plass should produce more balanced or equal lines")
    }

    @Test func knuth_plass_multipleFlexItems() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: 20...40, spacing: 0),
            .init(size: 20...40, spacing: 10),
            .init(size: 20...40, spacing: 10)
        ], in: 80)
        #expect(!result.isEmpty)
        // All items should fit on one line since they're flexible
        #expect(result.count == 1)
    }

    @Test func knuth_plass_newLine_withFlex() {
        let sut = KnuthPlassLineBreaker()
        let result = sut.wrapItemsToLines(items: [
            .init(size: .rigid(30), spacing: 0),
            .init(size: 20...60, spacing: 10, shouldStartInNewLine: true)
        ], in: 100)
        #expect(result.count == 2, "shouldStartInNewLine should force a new line")
        #expect(result[0].count == 1)
        #expect(result[1].count == 1)
    }
}

private extension ClosedRange {
    static func rigid(_ value: Bound) -> Self {
        value ... value
    }
}
