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
}

private extension ClosedRange {
    static func rigid(_ value: Bound) -> Self {
        value ... value
    }
}
