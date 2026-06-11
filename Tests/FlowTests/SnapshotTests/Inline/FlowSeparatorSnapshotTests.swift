import SwiftUI
import Testing

@testable import Flow

@Suite(.tags(.snapshot))
struct SeparatorSnapshots {
    /// Item separators sit in the gaps between items on the same line (B between A and C).
    @Test func itemSeparator_onOneLine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 1, verticalSpacing: 0)
        let separator = TestSubview(size: 1 × 1)
        separator[SeparatorRoleLayoutValueKey.self] = .itemSeparator
        let result = sut.layout([3 × 1, separator, 3 × 1], in: 10 × 2)
        assertLayoutRendering(result) {
            """
            +----------+
            |AAA B CCC |
            |          |
            +----------+
            """
        }
    }

    /// When the gap wraps, the line separator (B) becomes its own full-width line between rows.
    @Test func lineSeparator_betweenRows() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let separator = CGSize(width: 0, height: 1) ... CGSize(width: .infinity, height: 1)
        separator[SeparatorRoleLayoutValueKey.self] = .lineSeparator
        let result = sut.layout([3 × 1, separator, 3 × 1], in: 3 × 3)
        assertLayoutRendering(result) {
            """
            +---+
            |AAA|
            |BBB|
            |CCC|
            +---+
            """
        }
    }

    /// With both configured, a gap on one line draws the item separator (B) and hides the line
    /// separator (C, parked off-canvas); D is the second item.
    @Test func itemSeparatorWins_whenItemsShareALine() {
        let sut: FlowLayout = .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
        let itemSeparator = TestSubview(size: 1 × 1)
        itemSeparator[SeparatorRoleLayoutValueKey.self] = .itemSeparator
        let lineSep = CGSize(width: 0, height: 1) ... CGSize(width: .infinity, height: 1)
        lineSep[SeparatorRoleLayoutValueKey.self] = .lineSeparator
        let result = sut.layout([3 × 1, itemSeparator, lineSep, 3 × 1], in: 8 × 2)
        assertLayoutRendering(result) {
            """
            +--------+
            |AAABDDD |
            |        |
            +--------+
            """
        }
    }
}
