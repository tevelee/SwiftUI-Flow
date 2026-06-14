import Testing

@testable import Flow
@testable import FlowSeparators

@Suite(.tags(.requirements))
struct SeparatorPlanTests {
    @Test func noSeparators_yieldsAllContentNoGaps() {
        let plan = SeparatorPlan(
            roles: [.content, .content, .content],
            isLineBreak: [false, false, false]
        )
        #expect(plan.contentIndices == [0, 1, 2])
        #expect(plan.separatorIndices.isEmpty)
        #expect(plan.gap(before: 1) == nil)
        #expect(plan.gap(before: 2) == nil)
    }

    @Test func bothSeparatorsInGap_arePairedToTheFollowingItem() {
        // content, itemSep, lineSep, content
        let plan = SeparatorPlan(
            roles: [.content, .itemSeparator, .lineSeparator, .content],
            isLineBreak: [false, false, false, false]
        )
        #expect(plan.contentIndices == [0, 3])
        #expect(plan.separatorIndices == [1, 2])
        #expect(plan.position(ofContentIndex: 3) == 1)
        #expect(plan.gap(before: 1) == .init(itemSeparator: 1, lineSeparator: 2, isEligible: true))
        // No gap before the first item — separators never appear at the leading edge.
        #expect(plan.gap(before: 0) == nil)
    }

    @Test func onlyItemSeparators_leaveLineSeparatorNil() {
        let plan = SeparatorPlan(
            roles: [.content, .itemSeparator, .content, .itemSeparator, .content],
            isLineBreak: [false, false, false, false, false]
        )
        #expect(plan.contentIndices == [0, 2, 4])
        #expect(plan.separatorIndices == [1, 3])
        #expect(plan.gap(before: 1) == .init(itemSeparator: 1, lineSeparator: nil, isEligible: true))
        #expect(plan.gap(before: 2) == .init(itemSeparator: 3, lineSeparator: nil, isEligible: true))
    }

    @Test func gapTouchingLineBreak_isIneligible() {
        // content, itemSep, lineSep, LineBreak(content), itemSep, lineSep, content
        let plan = SeparatorPlan(
            roles: [.content, .itemSeparator, .lineSeparator, .content, .itemSeparator, .lineSeparator, .content],
            isLineBreak: [false, false, false, true, false, false, false]
        )
        #expect(plan.contentIndices == [0, 3, 6])
        #expect(plan.gap(before: 1)?.isEligible == false)
        #expect(plan.gap(before: 2)?.isEligible == false)
    }

    @Test func singleContentItem_hasNoGaps() {
        let plan = SeparatorPlan(roles: [.content], isLineBreak: [false])
        #expect(plan.contentIndices == [0])
        #expect(plan.separatorIndices.isEmpty)
        #expect(plan.gap(before: 0) == nil)
    }

    @Test func empty_isStable() {
        let plan = SeparatorPlan(roles: [], isLineBreak: [])
        #expect(plan.contentIndices.isEmpty)
        #expect(plan.separatorIndices.isEmpty)
        #expect(plan.position(ofContentIndex: 0) == nil)
        #expect(plan.gap(before: 0) == nil)
    }
}
