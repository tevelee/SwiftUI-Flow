# Contributing to SwiftUI-Flow

Thank you for your interest in contributing! SwiftUI-Flow provides `HFlow` and `VFlow` — flow layouts for SwiftUI that wrap their content across lines, with control over alignment, spacing, distribution, flexibility, and line breaks. Contributions of all kinds are welcome: bug fixes, new layout capabilities, documentation, and performance work.

---

## Getting started

**Prerequisites:**
- Xcode 16+ (Swift 6 toolchain). The test target depends on [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing), which pulls in WebKit — it must be built with the **Xcode-bundled** toolchain, not a standalone swift.org toolchain.
- `git clone https://github.com/tevelee/SwiftUI-Flow.git && cd SwiftUI-Flow`

**Build:**
```bash
swift build
```

**Run the test suite** (required before submitting a PR):
```bash
# Deterministic suite — unit, integration, and ASCII snapshot tests.
swift test --skip ImageSnapshots --skip ReadmeSnapshotTests
```

> **Why skip the image suites?** The `*ImageSnapshots` and `ReadmeSnapshotTests` suites are pixel-for-pixel comparisons of rendered SwiftUI views. They only reproduce on the exact OS/Xcode combination that recorded them, so they are excluded from CI and from the standard local run. The unit, integration, and ASCII-layout snapshot tests are deterministic and platform-independent. If you change rendering and want to re-record the image baselines, do it locally and review the diff carefully (see [Testing](#testing)).

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
   swift test --skip ImageSnapshots --skip ReadmeSnapshotTests
   ```
5. **Open a PR** against `main`. Fill in the PR template and add a label so the automated release notes categorise it correctly.

---

## Testing

Tests live in `Tests/FlowTests/`, organised by kind:

- `Unit/` — pure layout math (line breaking, sizing). Platform-independent.
- `Integration/` — end-to-end layout behaviour through the `Layout` engine using `TestSubview` fixtures.
- `Snapshot/SnapshotTests.swift` — **ASCII** snapshots of computed frames (deterministic, run everywhere).
- `Snapshot/ImageSnapshotTests.swift` & `ReadmeSnapshotTests.swift` — **PNG** snapshots, `#if os(macOS)`-gated and environment-sensitive (not run in CI).

The library uses **Swift Testing** (`@Suite`, `@Test`, `#expect`).

**Running specific tests:**
```bash
swift test --filter LineBreakingTests
swift test --filter "FlexibilityTests/multipleFlexItems_allGrow"
```

**Re-recording image snapshots** (only when you intentionally change rendering):
1. Set `withSnapshotTesting(record: .all)` / `isRecording` locally, or delete the affected files under `__Snapshots__/`.
2. Run the image suites on macOS, then **review every regenerated PNG** before committing.
3. Note in the PR that snapshots were re-recorded and why.

---

## Code style

- 4-space indentation.
- All public declarations require `///` doc comments.
- Prefer early exits (`guard`) and small, composable helpers — match the surrounding code.

---

## Documentation

Every public declaration needs a `///` doc comment. User-facing guides live in `Sources/Flow/Flow.docc/`; when you add or change a feature (alignment, distribution, flexibility, spacing, line breaks), update the matching article. DocC is built on every PR and published to GitHub Pages from `main`.

---

## Reporting bugs and requesting features

- **Bugs:** use the [Bug report](.github/ISSUE_TEMPLATE/bug_report.yml) template — a minimal `HFlow`/`VFlow` reproduction and a screenshot help most.
- **Features:** use the [Feature request](.github/ISSUE_TEMPLATE/feature_request.yml) template.
- **Questions:** use [GitHub Discussions](https://github.com/tevelee/SwiftUI-Flow/discussions) rather than issues.
- **Security vulnerabilities:** see [SECURITY.md](SECURITY.md) — do not open a public issue.
