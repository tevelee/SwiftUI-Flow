# Contributing to SwiftUI-Flow

Thank you for your interest in contributing! SwiftUI-Flow provides `HFlow` and `VFlow` — flow layouts for SwiftUI that wrap their content across lines, with control over alignment, spacing, distribution, flexibility, and line breaks. Contributions of all kinds are welcome: bug fixes, new layout capabilities, documentation, and performance work.

---

## Getting started

**Prerequisites:**
- Xcode 16+ (Swift 6 toolchain). The full test suite depends on [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing), which pulls in WebKit — it must be built with the **Xcode-bundled** toolchain, not a standalone swift.org toolchain.
- `git clone https://github.com/tevelee/SwiftUI-Flow.git && cd SwiftUI-Flow`

**Build:**
```bash
swift build
```

**All optional dependencies are opt-in.** Snapshot, property-based, and documentation libraries are only resolved when you opt in via environment variables. This keeps plain `swift build` and dependency resolution lean for library consumers. The suites that need them are excluded from the test target unless the matching variable is set:

| Variable | Enables |
|---|---|
| `FLOW_SNAPSHOT_TESTING` | The `SnapshotTests/` suites and all inline ASCII-transcript assertions in `IntegrationTests/` |
| `FLOW_PROPERTY_TESTING` | The property-based suite (`FlowInvariantRequirementTests`) |
| `FLOW_DOCC` | The `swift-docc-plugin` for documentation generation |

**Run the test suite** (required before submitting a PR) — opt into both so the full suite runs:
```bash
FLOW_SNAPSHOT_TESTING=1 FLOW_PROPERTY_TESTING=1 swift test
```

Plain `swift test` (no variables) still works, but compiles and runs only the dependency-free subset — use the full command above before submitting. SwiftPM caches manifest evaluation, so after toggling a variable on a previously built checkout you may need `swift package reset` (or a clean checkout) for it to take effect.

The image snapshot suites are part of the contract for this UI library. If a render snapshot fails, either fix the regression or intentionally re-record the affected baseline and review the image diff carefully.

---

## Supported platforms & Swift versions

| | Swift 5.9 (`Package.swift`) | Swift 6.0 (`Package@swift-6.swift`) |
|---|---|---|
| Platforms | iOS 16, macOS 13, tvOS 16, watchOS 9 | + visionOS 1 |
| Language mode | 5 | 6 (strict concurrency) |

CI builds the library for every platform on each push, runs the deterministic suite on macOS across Swift 5.9 / 6.0 / latest, and runs it on the iOS Simulator. Keep both manifests in sync when changing dependencies or settings.

---

## Development workflow

1. **Fork** the repository and branch from `main`:
   ```bash
   git checkout -b feature/my-change
   ```
2. **Write a test first** (TDD). New behaviour should have a failing test before any implementation.
3. **Implement** the minimal code to make it pass.
4. **Verify** locally:
   ```bash
   FLOW_SNAPSHOT_TESTING=1 FLOW_PROPERTY_TESTING=1 swift test
   swift-format lint --strict --recursive Sources Tests
   swiftlint lint --strict
   ```
5. **Open a PR** against `main`. Fill in the PR template and add a label so the automated release notes categorise it correctly.

---

## Testing

Tests live in `Tests/FlowTests/`, organized by role:

- `UnitTests/` — pure layout math such as line breaking and sizing. These tests should assert exact output structures, not broad properties.
- `IntegrationTests/` — end-to-end `Layout` behavior using `TestSubview` fixtures. Requirement tests should assert exact reported sizes and placements.
- `IntegrationTests/PublicAPI/` — public API surface tests: initializer mapping, rendering, layout direction.
- `PropertyTests/` — property-based invariant tests (requires `FLOW_PROPERTY_TESTING=1`).
- `SnapshotTests/Inline/` — ASCII snapshots of computed frames. Use these for broad visual coverage of layout structure (requires `FLOW_SNAPSHOT_TESTING=1`).
- `SnapshotTests/Image/` — PNG snapshots of rendered SwiftUI views. Use these for render verification and documentation examples (requires `FLOW_SNAPSHOT_TESTING=1`).

The library uses **Swift Testing** (`@Suite`, `@Test`, `#expect`) and suite tags:

- `.requirements` — behavior-defining unit and integration tests.
- `.snapshot` — text or image snapshot tests.
- `.imageSnapshot` — pixel-rendered snapshot tests.
- `.readmeSnapshot` — snapshots used by README examples.
- `.lazyLayout` — lazy flow layout coverage.
- `.regression` — tests that lock down a specific past bug.

Prefer exact assertions for requirements. Snapshot tests are still required for render verification, but they should not be the only place a behavioral rule is described.

**Running specific tests:**
Prefix with the opt-in variables (see [Getting started](#getting-started)) whenever the filter targets a snapshot, ASCII-transcript, or property-based suite — otherwise those tests are excluded and the filter matches nothing.
```bash
swift test --filter FlowAlignmentRequirementTests
swift test --filter LineBreakingTests
FLOW_SNAPSHOT_TESTING=1 swift test --filter FlowDistributionRequirementTests
FLOW_SNAPSHOT_TESTING=1 swift test --filter FlowLineBreakRequirementTests
FLOW_SNAPSHOT_TESTING=1 swift test --filter ReadmeSnapshotTests
FLOW_PROPERTY_TESTING=1 swift test --filter FlowInvariantRequirementTests
```

**Re-recording snapshots** is allowed when the expected rendering or layout output intentionally changes:
```bash
SNAPSHOT_TESTING_RECORD=all FLOW_SNAPSHOT_TESTING=1 swift test --filter ImageSnapshots
SNAPSHOT_TESTING_RECORD=all FLOW_SNAPSHOT_TESTING=1 swift test --filter ReadmeSnapshotTests
```

Review every changed file under `Tests/FlowTests/SnapshotTests/Image/__Snapshots__/` before committing. A PR that re-records snapshots should also include exact requirement tests for the behavior that changed, unless the change is purely visual.

---

## Code style

- 4-space indentation.
- All public declarations require `///` doc comments.
- Prefer early exits (`guard`) and small, composable helpers — match the surrounding code.

**Linting** is enforced by [`swift-format`](https://github.com/swiftlang/swift-format) and [`SwiftLint`](https://github.com/realm/SwiftLint). Install both with Homebrew:
```bash
brew install swift-format swiftlint
```

Check for issues:
```bash
swift-format lint --strict --recursive Sources Tests
swiftlint lint --strict
```

Auto-fix most issues in one pass:
```bash
swift-format format --recursive --in-place Sources Tests
swiftlint --fix
```

CI runs both linters on every PR and will fail on any violation. A bot also applies auto-fixes as a commit when it can resolve issues without ambiguity.

---

## Documentation

Every public declaration needs a `///` doc comment. User-facing guides live in `Sources/Flow/Flow.docc/`; when you add or change a feature (alignment, distribution, flexibility, spacing, line breaks), update the matching article. DocC is built on every PR and published to GitHub Pages from `main`.

---

## Reporting bugs and requesting features

- **Bugs:** use the [Bug report](.github/ISSUE_TEMPLATE/bug_report.yml) template — a minimal `HFlow`/`VFlow` reproduction and a screenshot help most.
- **Features:** use the [Feature request](.github/ISSUE_TEMPLATE/feature_request.yml) template.
- **Questions:** use [GitHub Discussions](https://github.com/tevelee/SwiftUI-Flow/discussions) rather than issues.
- **Security vulnerabilities:** see [SECURITY.md](SECURITY.md) — do not open a public issue.
