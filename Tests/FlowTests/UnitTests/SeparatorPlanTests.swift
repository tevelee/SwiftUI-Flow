import Testing

@testable import Flow

@Suite(.tags(.requirements))
struct SeparatorPlanTests {
    @Test(arguments: [false, true])
    func explicitSeparator_overridesAutomaticSeparator(isEmpty: Bool) {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .lineSeparator),
            .init(role: .itemSeparatorOverride(isEmpty: isEmpty)),
            .init(role: .itemSeparator),
            .init(role: .lineSeparator),
            .init(role: .content),
        ])
        #expect(plan.contentIndices == [0, 6])
        #expect(plan.separatorIndices == [1, 2, 3, 4, 5])
        #expect(separatorPlanDiagram(plan) == (isEmpty ? "A -- item:none / line:F --> G" : "A -- item:D / line:F --> G"))
    }

    @Test func consecutiveExplicitSeparators_useLast_andIgnoreEdges() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .itemSeparatorOverride(isEmpty: false)),
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: false)),
            .init(role: .itemSeparatorOverride(isEmpty: true)),
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: false)),
        ])
        #expect(plan.contentIndices == [1, 4])
        #expect(plan.itemSeparator(before: 1, after: 0) == nil)
        #expect(plan.itemSeparator(before: 4, after: 1) == nil)
        #expect(plan.itemSeparator(before: 5, after: 4) == nil)
    }

    @Test func pooledLineSeparators_respectManualBreaksOverridesAndOverflow() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: true)),
            .init(role: .content),
            .init(role: .lineBreak),
            .init(role: .content),
            .init(role: .content),
            .init(role: .pooledLineSeparator(0)),
            .init(role: .pooledLineSeparator(1)),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.lineSeparator(before: 2, atBoundary: 0) == 6)
        #expect(plan.itemSeparator(before: 2, after: 0) == nil, "An empty item override does not suppress a line boundary")
        #expect(plan.lineSeparator(before: 3, atBoundary: 0) == nil)
        #expect(plan.lineSeparator(before: 4, atBoundary: 0) == nil)
        #expect(plan.lineSeparator(before: 5, atBoundary: 1) == 7)
        #expect(plan.lineSeparator(before: 8, atBoundary: 1) == nil, "Overflow has no automatic line-separator builder gap")
    }

    @Test func noSeparators_yieldsAllContentNoGaps() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .content),
            .init(role: .content),
        ])
        #expect(plan.contentIndices == [0, 1, 2])
        #expect(plan.separatorIndices.isEmpty)
        #expect(plan.itemSeparator(before: 1, after: 0) == nil)
        #expect(plan.itemSeparator(before: 2, after: 1) == nil)
    }

    @Test func bothSeparatorsInGap_arePairedToTheFollowingItem() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .lineSeparator),
            .init(role: .content),
        ])
        #expect(plan.contentIndices == [0, 3])
        #expect(plan.separatorIndices == [1, 2])
        #expect(separatorPlanDiagram(plan) == "A -- item:B / line:C --> D")
        #expect(plan.itemSeparator(before: 0, after: 0) == nil)
        #expect(plan.lineSeparator(before: 0) == nil)
    }

    @Test func onlyItemSeparators_leaveLineSeparatorNil() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .content),
        ])
        #expect(plan.contentIndices == [0, 2, 4])
        #expect(plan.separatorIndices == [1, 3])
        #expect(plan.itemSeparator(before: 2, after: 0) == 1)
        #expect(plan.itemSeparator(before: 4, after: 2) == 3)
        #expect(plan.lineSeparator(before: 2) == nil)
        #expect(plan.lineSeparator(before: 4) == nil)
    }

    @Test func gapTouchingLineBreak_isIneligible() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .lineSeparator),
            .init(role: .lineBreak),
            .init(role: .itemSeparator),
            .init(role: .lineSeparator),
            .init(role: .content),
        ])
        #expect(plan.contentIndices == [0, 3, 6])
        #expect(plan.itemSeparator(before: 3, after: 0) == nil)
        #expect(plan.itemSeparator(before: 6, after: 3) == nil)
        #expect(plan.lineSeparator(before: 3) == nil)
        #expect(plan.lineSeparator(before: 6) == nil)
    }

    @Test func singleContentItem_hasNoGaps() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content)
        ])
        #expect(plan.contentIndices == [0])
        #expect(plan.separatorIndices.isEmpty)
        #expect(plan.itemSeparator(before: 0, after: 0) == nil)
        #expect(plan.lineSeparator(before: 0) == nil)
    }

    @Test func empty_isStable() {
        let plan = SeparatorPlan(subviews: [])
        #expect(plan.contentIndices.isEmpty)
        #expect(plan.separatorIndices.isEmpty)
        #expect(plan.itemSeparator(before: 0, after: 0) == nil)
        #expect(plan.lineSeparator(before: 0) == nil)
    }

    @Test(arguments: [false, true], [false, true])
    func overflowOverride_requiresBuilderOwnership(isEmpty: Bool, inOverflowBuilder: Bool) {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: isEmpty), origin: inOverflowBuilder ? .overflowBuilder : .flowContent),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.itemSeparator(before: 4, after: 0) == (inOverflowBuilder ? (isEmpty ? nil : 3) : 1))
    }

    @Test func overflowInheritance_followsCurrentRetainedItem() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: false)),
            .init(role: .content),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.itemSeparator(before: 5, after: 0) == 1)
        #expect(plan.itemSeparator(before: 5, after: 2) == 3)
    }

    @Test(arguments: [false, true])
    func consecutiveOverflowOverrides_useLast(isEmpty: Bool) {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: false), origin: .overflowBuilder),
            .init(role: .itemSeparatorOverride(isEmpty: isEmpty), origin: .overflowBuilder),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.itemSeparator(before: 3, after: 0) == (isEmpty ? nil : 2))
    }

    @Test func overflowAfterLineBreak_suppressesBuilderOverride() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .lineBreak),
            .init(role: .itemSeparatorOverride(isEmpty: false), origin: .overflowBuilder),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.itemSeparator(before: 4, after: 2) == nil)
        #expect(plan.itemSeparator(before: 4, after: 0) == 3)
    }

    @Test func builderContent_stopsOverflowOverrideSearch() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparator),
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: false), origin: .overflowBuilder),
            .init(role: .content, origin: .overflowBuilder),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.itemSeparator(before: 5, after: 0) == 1)
    }

    @Test func generatedSeparators_doNotHideOverflowOverride() {
        let plan = SeparatorPlan(subviews: [
            .init(role: .content),
            .init(role: .itemSeparatorOverride(isEmpty: false), origin: .overflowBuilder),
            .init(role: .itemSeparator, origin: .overflowBuilder),
            .init(role: .lineSeparator, origin: .overflowBuilder),
            .init(role: .content, origin: .overflowBuilder),
        ])
        #expect(plan.itemSeparator(before: 4, after: 0) == 1)
    }
}
