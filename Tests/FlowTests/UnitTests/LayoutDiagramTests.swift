import CoreFoundation
import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct LayoutDiagramTests {
    @Test func offGridFractions_areNotRoundedIntoPassingDiagrams() {
        let lines: WrappedLines = [[.init(index: 0, size: 1.25, leadingSpace: 0)]]
        #expect(wrappedLineDiagram(lines).hasPrefix("Off-grid"))
        expectWrappedLines(lines, unit: 0.25) { "AAAAA" }
    }

    @Test func duplicateItems_cannotMergeIntoOnePassingBar() {
        let duplicate: WrappedItem = .init(index: 0, size: 1, leadingSpace: 0)
        #expect(wrappedLineDiagram([[duplicate, duplicate]]).hasPrefix("Off-grid"))
    }
}
