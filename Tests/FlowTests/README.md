# Flow Test Strategy

The tests should read as executable layout requirements. Prefer small scenarios with explicit configuration, visible output, and exact geometry over broad tests that only assert that something did not crash.

Use [CoverageMatrix.md](CoverageMatrix.md) to track which layout behaviors are covered, partially covered, or still missing.

## Test Layers

- `Unit`: focused tests for pure algorithms and small helpers.
- `Integration/*RequirementTests`: normative behavior for public layout semantics. Add new edge cases here first.
- `Snapshot`: visual SwiftUI/image snapshots and broader render snapshots.

## Requirement Test Shape

For layout behavior tests, prefer this order:

```swift
let result = FlowLayoutScenario(
    layout: .horizontal(horizontalSpacing: 1, verticalSpacing: 0),
    subviews: [3 × 1, 3 × 1],
    proposal: 10 × 1
)
.layoutThatFits()

assertLayoutRendering(result) {
    """
    +-------+
    |AAA BBB|
    +-------+
    """
}
#expect(result.reportedSize == (7 × 1))
expectPlacements(result.subviews) {
    placed(at: 0, 0, size: 3 × 1)
    placed(at: 4, 0, size: 3 × 1)
}
```

Use `FlowLayoutScenario.assertExpectedLayout(size:) { ... }` when no render snapshot is needed. Use `assertExpectedSize(_:)` for sizing-only requirements. Keep the array-based `placements:` overload for generated expectations or large parameterized tables where constructing an array is clearer than a builder block.

## Property Tests

Use property checks for invariants that should hold across many configurations, not for exact geometry examples. Generated inputs should be small `Sendable` specs; build fresh `TestSubview` instances inside each property iteration so mutable placement state is never reused between generated cases.

Group property tests by the behavior being verified, not by generator implementation. Current property suites use:

- `Geometry`: finite placements, non-negative sizes, and containment.
- `Ordering`: visible traversal order.
- `Spacing`: nil spacing fallback equivalence for `.zero` subview spacing.
- `EdgeCases`: fractional geometry and non-overlap policy for non-negative spacing.
- `Metamorphic`: H/V transpose and monotonic proposal checks.

Generated scenarios should identify themselves with a category (`common`, `edge`, `transpose`, `monotonic`, or `spacingFallback`) plus orientation, proposal, alignment, spacing, mode, controls, flex, priority, and subview summaries. Keep common generators focused on ordinary layouts; keep edge generators broad enough to include line breaks, new-line starts, priorities, flexibility, negative spacing, fractional values, and proposal edge cases.

Do not commit `.fixedSeed(...)` traits. When `PropertyBased` reports a failing seed, use it temporarily to reproduce and shrink the issue, then replace the failure with a named requirement test or fix the generator/invariant.

## Text Snapshots

`assertLayoutRendering` is the default text snapshot assertion for layout results. It renders each subview with a stable label (`A`, `B`, `C`, ...), so the snapshot shows which item occupies each cell. Visible overlaps are rendered as `*`; cells outside the reported size are clipped.

Use `assertLayoutTranscript` in addition to the render snapshot when the grid hides important behavior:

- zero-size line-break/layout-guide subviews
- fractional origins such as `0.5` or `1.5`
- negative spacing or other overlap scenarios
- any case where item identity is not enough to explain the requirement

Inline text snapshots live in the test source. To update them intentionally:

```sh
SNAPSHOT_TESTING_RECORD=failed swift test --filter FlowLineBreakRequirementTests
swift test --filter FlowLineBreakRequirementTests
```

Review the source diff after recording. The second command must pass without recording enabled.

## Image Snapshots

Keep PNG snapshots for rendered SwiftUI views; this is a UI library and real rendered output matters. Image snapshots live under `Tests/FlowTests/Snapshot/__Snapshots__`. Re-record only with an intentional visual change, then run `swift test` normally and inspect the changed images.

## Naming

Use `HFlow_...` and `VFlow_...` prefixes for orientation-specific behavior. Name tests as behavior statements, for example `HFlow_lineBreakMarker_forcesNewRow` or `VFlow_negativeSpacing_reducesColumnHeight`.
