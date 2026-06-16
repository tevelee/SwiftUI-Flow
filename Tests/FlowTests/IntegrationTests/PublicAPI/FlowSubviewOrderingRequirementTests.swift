import SwiftUI
import Testing

@testable import Flow

/// Integration tests for the FlowSubviewOrdering feature.
///
/// Each test exercises a documented behavior from the design spec:
/// - `.packed` reorders items by ideal breadth descending (FFD)
/// - `.natural` (default) preserves declaration order
/// - `.packed` silently ignores `LineBreak` / `startInNewLine` semantics
/// - `.packed` overrides `distributeItemsEvenly` (greedy breaker always used)
/// - `.packed` is compatible with `justified: true`
@Suite(.tags(.requirements))
struct FlowSubviewOrderingRequirementTests {

    // MARK: - Packed ordering

    @Test func HFlow_packed_ordersItemsByBreadthDescending() {
        // Items in declaration order: widths [3, 7, 1, 5], container width = 10, no spacing.
        // Sorted by ideal breadth descending: [7, 5, 3, 1]
        // Greedy line fill:
        //   Line 1: [7] — try 5: 7+5=12>10, wrap. Line 1 = [7pt alone].
        //   Line 2: [5, 3, 1] — 5+3+1=9≤10, all fit. Line 2 = [5pt, 3pt, 1pt].
        // reportedSize.width = max(7, 9) = 9.
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
                .withSubviewOrdering(.packed),
            subviews: [3 × 1, 7 × 1, 1 × 1, 5 × 1],
            proposal: 10 × 100
        )
        .assertExpectedLayout(
            size: 9 × 2,
            placements: [
                .init(position: (5, 1), size: 3 × 1),  // subview[0] (3pt) — 2nd on line 2
                .init(position: (0, 0), size: 7 × 1),  // subview[1] (7pt) — alone on line 1
                .init(position: (8, 1), size: 1 × 1),  // subview[2] (1pt) — 3rd on line 2
                .init(position: (0, 1), size: 5 × 1),  // subview[3] (5pt) — 1st on line 2
            ]
        )
    }

    @Test func VFlow_packed_ordersItemsByDepthDescending() {
        // Items in declaration order: heights [3, 7, 1, 5], container height = 10, no spacing.
        // Sorted by ideal depth descending: [7, 5, 3, 1]
        // Greedy column fill:
        //   Col 1: [7] — try 5: 7+5=12>10, wrap. Col 1 = [7pt alone].
        //   Col 2: [5, 3, 1] — 5+3+1=9≤10, all fit. Col 2 = [5pt, 3pt, 1pt].
        // reportedSize.height = max(7, 9) = 9.
        FlowLayoutScenario(
            layout: .vertical(horizontalSpacing: 0, verticalSpacing: 0)
                .withSubviewOrdering(.packed),
            subviews: [1 × 3, 1 × 7, 1 × 1, 1 × 5],
            proposal: 100 × 10
        )
        .assertExpectedLayout(
            size: 2 × 9,
            placements: [
                .init(position: (1, 5), size: 1 × 3),  // subview[0] (3pt) — 2nd in col 2
                .init(position: (0, 0), size: 1 × 7),  // subview[1] (7pt) — alone in col 1
                .init(position: (1, 8), size: 1 × 1),  // subview[2] (1pt) — 3rd in col 2
                .init(position: (1, 0), size: 1 × 5),  // subview[3] (5pt) — 1st in col 2
            ]
        )
    }

    // MARK: - Natural ordering (regression)

    @Test func HFlow_natural_preservesDeclarationOrder() {
        // Same items as the packed test, but natural order. Items fill in order [3,7,1,5].
        // Line 1: [3, 7] = 10, line 2: [1, 5] = 6
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0),
            subviews: [3 × 1, 7 × 1, 1 × 1, 5 × 1],
            proposal: 10 × 100
        )
        .assertExpectedLayout(
            size: 10 × 2,
            placements: [
                .init(position: (0, 0), size: 3 × 1),
                .init(position: (3, 0), size: 7 × 1),
                .init(position: (0, 1), size: 1 × 1),
                .init(position: (1, 1), size: 5 × 1),
            ]
        )
    }

    // MARK: - Interaction with distributeItemsEvenly

    @Test func HFlow_packed_overridesDistributeItemsEvenly_usesGreedyBreaker() {
        // With distributeItemsEvenly=true and no packed, Knuth-Plass would spread
        // items [4, 4, 2] across two lines as [4] / [4, 2] to balance waste:
        //   option [4,4]/[2]: squared waste = 0 + 36 = 36
        //   option [4]/[4,2]: squared waste = 16 + 4 = 20  ← KP picks this
        // .packed overrides distributeItemsEvenly and uses greedy, which packs [4,4]/[2]
        // → subview[1] (4pt) lands on line 1 at x=4, not on line 2 at y=1.
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0, distributeItemsEvenly: true)
                .withSubviewOrdering(.packed),
            subviews: [4 × 1, 4 × 1, 2 × 1],
            proposal: 8 × 100
        )
        .assertExpectedLayout(
            size: 8 × 2,
            placements: [
                .init(position: (0, 0), size: 4 × 1),
                .init(position: (4, 0), size: 4 × 1),
                .init(position: (0, 1), size: 2 × 1),
            ]
        )
    }

    // MARK: - LineBreak interaction

    @Test func HFlow_packed_ignoresLineBreakView() {
        // LineBreak is a zero-size view with isLineBreak = true.
        // Under .packed the LineBreak flag is cleared, so it sorts to the end (size=0)
        // and is treated as a normal zero-size item — no forced break.
        // Items [5, LB(0), 3] sorted packed: [5, 3, LB(0)] → all fit on line 1 (5+3+0=8).
        let lineBreak = testLineBreakSubview()
        let subviews: [TestSubview] = [5 × 1, lineBreak, 3 × 1]
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0)
                .withSubviewOrdering(.packed),
            subviews: subviews,
            proposal: 8 × 100
        )
        .assertExpectedLayout(
            size: 8 × 1,
            placements: [
                .init(position: (0, 0), size: 5 × 1),  // subview[0] (5pt) — 1st on line 1
                .init(position: (8, 0.5), size: .zero),  // LineBreak — last, centered vertically
                .init(position: (5, 0), size: 3 × 1),  // subview[2] (3pt) — 2nd on line 1
            ]
        )
    }

    // MARK: - Justified interaction

    @Test func HFlow_packed_isCompatibleWithJustified() {
        // When justified=true, items are stretched to fill each line.
        // Under .packed, items [4, 2, 3, 1] sorted: [4, 3, 2, 1] in 7pt container.
        //   Line 1 greedy: [4, 3] = 7 → exactly fills, no stretch needed.
        //   Line 2 greedy: [2, 1] = 3 → justified: gap=4, subview[3] at x=6.
        // (justified=true applies to ALL lines in this layout, including the last.)
        FlowLayoutScenario(
            layout: .horizontal(horizontalSpacing: 0, verticalSpacing: 0, justified: true)
                .withSubviewOrdering(.packed),
            subviews: [4 × 1, 2 × 1, 3 × 1, 1 × 1],
            proposal: 7 × 100
        )
        .assertExpectedLayout(
            size: 7 × 2,
            placements: [
                .init(position: (0, 0), size: 4 × 1),  // subview[0] (4pt) — 1st on line 1
                .init(position: (0, 1), size: 2 × 1),  // subview[1] (2pt) — 1st on line 2
                .init(position: (4, 0), size: 3 × 1),  // subview[2] (3pt) — 2nd on line 1
                .init(position: (6, 1), size: 1 × 1),  // subview[3] (1pt) — 2nd on line 2 (justified)
            ]
        )
    }
}
