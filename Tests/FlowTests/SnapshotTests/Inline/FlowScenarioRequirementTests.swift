import SwiftUI
import Testing

@testable import Flow

/// Scenario-based requirement tests: one concrete setup, varied incrementally.
/// Each family documents how features compose in practice rather than in isolation.
@Suite(.tags(.requirements))
struct FlowScenarioRequirementTests {

    // MARK: - Tag Row
    //
    // Five items of different widths in a 14-unit-wide HFlow container.
    // Baseline row distribution:
    //   Row 1: A(3) B(5) C(2)  — 12 wide, 2 px slack
    //   Row 2: D(4) E(3)       —  8 wide, 6 px slack

    @Suite("TagRow")
    struct TagRowScenarios {

        private func scenario(subviews: [TestSubview], justified: Bool = false) -> FlowLayoutScenario {
            FlowLayoutScenario(
                layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 1, justified: justified),
                subviews: subviews,
                proposal: ProposedViewSize(width: 14, height: nil)
            )
        }

        // MARK: Baseline

        @Test func baseline() {
            let result = scenario(subviews: [3 × 1, 5 × 1, 2 × 1, 4 × 1, 3 × 1]).layoutThatFits()
            #expect(result.reportedSize == (12 × 3))
            assertLayoutRendering(result) {
                """
                +------------+
                |AAA BBBBB CC|
                |            |
                |DDDD EEE    |
                +------------+
                """
            }
        }

        // MARK: Flexibility — single item

        @Test func E_flexible() {
            let result = scenario(subviews: [
                3 × 1,
                5 × 1,
                2 × 1,
                4 × 1,
                3 × 1 ... inf × 1,
            ]).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA BBBBB CC  |
                |              |
                |DDDD EEEEEEEEE|
                +--------------+
                """
            }
        }

        @Test func B_flexible() {
            let result = scenario(subviews: [
                3 × 1,
                5 × 1 ... inf × 1,
                2 × 1,
                4 × 1,
                3 × 1,
            ]).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA BBBBBBB CC|
                |              |
                |DDDD EEE      |
                +--------------+
                """
            }
        }

        // MARK: Flexibility — two items sharing a row

        @Test func D_and_E_flexible() {
            let result = scenario(subviews: [
                3 × 1,
                5 × 1,
                2 × 1,
                4 × 1 ... inf × 1,
                3 × 1 ... inf × 1,
            ]).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA BBBBB CC  |
                |              |
                |DDDDDDD EEEEEE|
                +--------------+
                """
            }
        }

        // MARK: Maximum flex — item promotes to its own row

        @Test func D_maximumFlex() {
            let d = (4 × 1 ... inf × 1).flexibility(.maximum)
            let result = scenario(subviews: [3 × 1, 5 × 1, 2 × 1, d, 3 × 1]).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA BBBBB CC  |
                |              |
                |DDDDDDDDDDDDDD|
                |              |
                |EEE           |
                +--------------+
                """
            }
        }

        // MARK: Line break — forced restructuring

        @Test func lineBreakAfterB() {
            let result = scenario(subviews: [
                3 × 1,
                5 × 1,
                testLineBreakSubview(),
                2 × 1,
                4 × 1,
                3 × 1,
            ]).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +-----------+
                |AAA BBBBB  |
                |           |
                |DD EEEE FFF|
                +-----------+
                """
            }
            assertLayoutTranscript(result) {
                """
                reportedSize: 11×3
                placements:
                A[0]: origin: 0×0, size: 3×1
                B[1]: origin: 4×0, size: 5×1
                C[2]: origin: 0×2.5, size: 0×0
                D[3]: origin: 0×2, size: 2×1
                E[4]: origin: 3×2, size: 4×1
                F[5]: origin: 8×2, size: 3×1
                """
            }
        }

        // MARK: Justification — space distributed between items

        @Test func justified() {
            let result = scenario(subviews: [3 × 1, 5 × 1, 2 × 1, 4 × 1, 3 × 1], justified: true).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA  BBBBB  CC|
                |              |
                |DDDD       EEE|
                +--------------+
                """
            }
            assertLayoutTranscript(result) {
                """
                reportedSize: 14×3
                placements:
                A[0]: origin: 0×0, size: 3×1
                B[1]: origin: 5×0, size: 5×1
                C[2]: origin: 12×0, size: 2×1
                D[3]: origin: 0×2, size: 4×1
                E[4]: origin: 11×2, size: 3×1
                """
            }
        }

        @Test func justified_withLineBreak() {
            let result = scenario(
                subviews: [
                    3 × 1,
                    5 × 1,
                    testLineBreakSubview(),
                    2 × 1,
                    4 × 1,
                    3 × 1,
                ],
                justified: true
            ).layoutThatFits()
            assertLayoutRendering(result) {
                """
                +--------------+
                |AAA      BBBBB|
                |              |
                |DD  EEEE   FFF|
                +--------------+
                """
            }
            assertLayoutTranscript(result) {
                """
                reportedSize: 14×3
                placements:
                A[0]: origin: 0×0, size: 3×1
                B[1]: origin: 9×0, size: 5×1
                C[2]: origin: 0×2.5, size: 0×0
                D[3]: origin: 0×2, size: 2×1
                E[4]: origin: 4.5×2, size: 4×1
                F[5]: origin: 11×2, size: 3×1
                """
            }
        }
    }
}
