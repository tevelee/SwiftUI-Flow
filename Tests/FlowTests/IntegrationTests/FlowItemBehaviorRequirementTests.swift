import SwiftUI
import Testing

@testable import Flow

/// Integration tests for item-level behavioral features: flexibility, line-break markers,
/// `shouldStartInNewLine`, wrapping text, and justified distribution.
///
/// These complement the snapshot tests in `SnapshotTests/Inline/` with coordinate-level
/// assertions that run without the `FLOW_SNAPSHOT_TESTING` environment variable.
@Suite(.tags(.requirements))
struct FlowItemBehaviorRequirementTests {

    // MARK: - Flexibility

    @Suite("Flexibility")
    struct FlexibilityTests {

        @Test func HFlow_naturalFlexItem_expandsToFillRemainingLineWidth() {
            FlowLayoutScenario(
                layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
                subviews: [3 × 1, 1 × 1 ... 6 × 1],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 10 × 1) {
                placed(at: 0, 0, size: 3 × 1)
                placed(at: 4, 0, size: 6 × 1)
            }
        }

        @Test func HFlow_minimumFlexItem_doesNotGrow_whileNaturalFlexItemFills() {
            FlowLayoutScenario(
                layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
                subviews: [
                    1 × 1 ... 6 × 1,
                    (1 × 1 ... 6 × 1).flexibility(.minimum),
                ],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 8 × 1) {
                placed(at: 0, 0, size: 6 × 1)
                placed(at: 7, 0, size: 1 × 1)
            }
        }

        @Test func HFlow_maximumFlexItem_forcedToOwnRow_whenFullGrowthDoesNotFit() {
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 1,
                    verticalSpacing: 0
                ),
                subviews: [
                    3 × 1,
                    (1 × 1 ... 10 × 1).flexibility(.maximum),
                    3 × 1,
                ],
                proposal: 10 × 3
            )
            .assertExpectedLayout(size: 10 × 3) {
                placed(at: 0, 0, size: 3 × 1)
                placed(at: 0, 1, size: 10 × 1)
                placed(at: 0, 2, size: 3 × 1)
            }
        }

        @Test func VFlow_naturalFlexItem_expandsToFillRemainingColumnHeight() {
            FlowLayoutScenario(
                layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1),
                subviews: [1 × 3, 1 × 1 ... 1 × 6],
                proposal: 1 × 10
            )
            .assertExpectedLayout(size: 1 × 10) {
                placed(at: 0, 0, size: 1 × 3)
                placed(at: 0, 4, size: 1 × 6)
            }
        }

        @Test func VFlow_maximumFlexItem_forcedToOwnColumn_whenFullGrowthDoesNotFit() {
            FlowLayoutScenario(
                layout: .vertical(
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 1
                ),
                subviews: [
                    1 × 3,
                    (1 × 1 ... 1 × 10).flexibility(.maximum),
                    1 × 3,
                ],
                proposal: 3 × 10
            )
            .assertExpectedLayout(size: 3 × 10) {
                placed(at: 0, 0, size: 1 × 3)
                placed(at: 1, 0, size: 1 × 10)
                placed(at: 2, 0, size: 1 × 3)
            }
        }
    }

    // MARK: - Line break markers

    @Suite("LineBreak")
    struct LineBreakTests {

        @Test func HFlow_lineBreakMarker_forcesNewRow() {
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 1,
                    verticalSpacing: 0
                ),
                subviews: [3 × 1, testLineBreakSubview(), 3 × 1],
                proposal: 10 × 2
            )
            .assertExpectedLayout(size: 3 × 2) {
                placed(at: 0, 0, size: 3 × 1)
                placed(at: 0, 1.5, size: .zero)
                placed(at: 0, 1, size: 3 × 1)
            }
        }

        @Test func HFlow_lineBreakAtStart_placesMarkerOnSameLineAsFollowingItem() {
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 1,
                    verticalSpacing: 0
                ),
                subviews: [testLineBreakSubview(), 3 × 1],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 3 × 1) {
                placed(at: 0, 0.5, size: .zero)
                placed(at: 0, 0, size: 3 × 1)
            }
        }

        @Test func HFlow_lineBreakAtEnd_doesNotIncreaseReportedSize() {
            // Trailing line-break marker occupies its own zero-depth row, so it
            // does NOT add to the reported height. The marker lands at y=1 (just
            // past the content boundary) on that empty row.
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 1,
                    verticalSpacing: 0
                ),
                subviews: [3 × 1, testLineBreakSubview()],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 3 × 1) {
                placed(at: 0, 0, size: 3 × 1)
                placed(at: 0, 1, size: .zero)
            }
        }

        @Test func VFlow_lineBreakMarker_forcesNewColumn() {
            // Uses .center horizontal alignment so the zero-size marker lands at x=1.5
            // (center of column 1, which is 1pt wide), distinguishing it from the
            // following item at x=1 — the same pattern as the HFlow test above.
            FlowLayoutScenario(
                layout: .vertical(
                    horizontalAlignment: .center,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 1
                ),
                subviews: [1 × 3, testLineBreakSubview(), 1 × 3],
                proposal: 2 × 10
            )
            .assertExpectedLayout(size: 2 × 3) {
                placed(at: 0, 0, size: 1 × 3)
                placed(at: 1.5, 0, size: .zero)
                placed(at: 1, 0, size: 1 × 3)
            }
        }
    }

    // MARK: - shouldStartInNewLine

    @Suite("NewLine")
    struct NewLineTests {

        @Test func HFlow_shouldStartInNewLine_forcesItemToNewRow_evenWhenItFits() {
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 0,
                    verticalSpacing: 0
                ),
                subviews: [3 × 1, testNewLineSubview(2 × 1)],
                proposal: 10 × 2
            )
            .assertExpectedLayout(size: 3 × 2) {
                placed(at: 0, 0, size: 3 × 1)
                placed(at: 0, 1, size: 2 × 1)
            }
        }

        @Test func HFlow_shouldStartInNewLineAtFirstItem_allowsFollowingItemsOnSameLine() {
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 1,
                    verticalSpacing: 0
                ),
                subviews: [testNewLineSubview(2 × 1), 2 × 1],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 5 × 1) {
                placed(at: 0, 0, size: 2 × 1)
                placed(at: 3, 0, size: 2 × 1)
            }
        }

        @Test func VFlow_shouldStartInNewLine_forcesItemToNewColumn() {
            FlowLayoutScenario(
                layout: .vertical(
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 0
                ),
                subviews: [1 × 3, testNewLineSubview(1 × 2)],
                proposal: 2 × 10
            )
            .assertExpectedLayout(size: 2 × 3) {
                placed(at: 0, 0, size: 1 × 3)
                placed(at: 1, 0, size: 1 × 2)
            }
        }
    }

    // MARK: - Wrapping text

    @Suite("WrappingText")
    struct WrappingTextTests {

        @Test func HFlow_wrappingText_reflowsIntoProposedWidth() {
            // WrappingText(6×1) wraps to 5×2 when proposed width is 5.
            // The three 1×1 chips are placed on the next row.
            FlowLayoutScenario(
                layout: .horizontal(
                    horizontalAlignment: .leading,
                    verticalAlignment: .center,
                    horizontalSpacing: 1,
                    verticalSpacing: 0
                ),
                subviews: [WrappingText(size: 6 × 1), 1 × 1, 1 × 1, 1 × 1],
                proposal: 5 × 3
            )
            .assertExpectedLayout(size: 5 × 3) {
                placed(at: 0, 0, size: 5 × 2)
                placed(at: 0, 2, size: 1 × 1)
                placed(at: 2, 2, size: 1 × 1)
                placed(at: 4, 2, size: 1 × 1)
            }
        }

        @Test func VFlow_wrappingText_reflowsIntoProposedHeight() {
            FlowLayoutScenario(
                layout: .vertical(
                    horizontalAlignment: .leading,
                    verticalAlignment: .top,
                    horizontalSpacing: 0,
                    verticalSpacing: 1
                ),
                subviews: [WrappingText(size: 1 × 6), 1 × 1, 1 × 1, 1 × 1],
                proposal: 3 × 5
            )
            .assertExpectedLayout(size: 3 × 5) {
                placed(at: 0, 0, size: 2 × 5)
                placed(at: 2, 0, size: 1 × 1)
                placed(at: 2, 2, size: 1 × 1)
                placed(at: 2, 4, size: 1 × 1)
            }
        }
    }

    // MARK: - Justified distribution

    @Suite("JustifiedDistribution")
    struct JustifiedDistributionTests {

        @Test func HFlow_justified_distributesRemainingSpaceBetweenItems() {
            // 3 items of 2pt with 1pt natural gaps in a 10pt container.
            // Natural width = 2+1+2+1+2 = 8. Extra 2pt divided across 2 gaps → 1pt each.
            FlowLayoutScenario(
                layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
                subviews: [2 × 1, 2 × 1, 2 × 1],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 10 × 1) {
                placed(at: 0, 0, size: 2 × 1)
                placed(at: 4, 0, size: 2 × 1)
                placed(at: 8, 0, size: 2 × 1)
            }
        }

        @Test func HFlow_justified_singleItemLine_notDistributed() {
            // A single-item line must not receive extra spacing.
            FlowLayoutScenario(
                layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
                subviews: [5 × 1],
                proposal: 10 × 1
            )
            .assertExpectedLayout(size: 10 × 1) {
                placed(at: 0, 0, size: 5 × 1)
            }
        }

        @Test func HFlow_justified_lineBreakMarker_doesNotReceiveDistributedSpace() {
            // Line-break markers are zero-size and must be excluded from distribution.
            let result = FlowLayoutScenario(
                layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0, justified: true),
                subviews: [3 × 1, testLineBreakSubview(), 3 × 1, 3 × 1],
                proposal: 10 × 2
            )
            .layoutThatFits()

            #expect(result.reportedSize == (10 × 2))
            expectPlacements(result.subviews) {
                placed(at: 0, 0, size: 3 × 1)
                placed(at: 0, 1.5, size: .zero)
                placed(at: 0, 1, size: 3 × 1)
                placed(at: 7, 1, size: 3 × 1)
            }
        }

        @Test func VFlow_justified_distributesRemainingSpaceBetweenItems() {
            FlowLayoutScenario(
                layout: .vertical(horizontalSpacing: 0, verticalSpacing: 1, justified: true),
                subviews: [1 × 2, 1 × 2, 1 × 2],
                proposal: 1 × 10
            )
            .assertExpectedLayout(size: 1 × 10) {
                placed(at: 0, 0, size: 1 × 2)
                placed(at: 0, 4, size: 1 × 2)
                placed(at: 0, 8, size: 1 × 2)
            }
        }
    }
}
