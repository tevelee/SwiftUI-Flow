# Flow benchmarks

The suite uses [ordo-one/benchmark](https://github.com/ordo-one/benchmark). Run it on macOS with
a Swift 6 toolchain, from the repository root:

```sh
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark run --target FlowBenchmarks
```

The environment flag enables the benchmark target and dependency in the Swift 6 manifest.
Ordinary library builds include neither. The plugin builds the benchmark in release mode.
Lazy workloads require macOS 14 or later.

## Workloads

Thirty-four hosted workloads exercise the public interface with ordinary `import Flow`:

- **HFlow and VFlow, initial text layout:** create and attach an `NSHostingView` containing 128
  text tags, then complete layout. Window and model creation happen outside measurement.
- **HFlow and VFlow, text resizing:** retain the hosting view and change the available breadth
  from 320pt to 180pt. Priming happens outside measurement; the timed update must change placement.
- **HFlow and VFlow, balanced flexible resizing:** resize 128 flexible tags from 960pt to 480pt
  with `distributeItemsEvenly`. This exercises candidate sizing as well as choosing line breaks.
- **HFlow and VFlow, balanced mixed priorities:** initially lay out or resize 128 flexible tags
  with varied growth limits and three layout priorities. This covers priority allocation and sorting
  while scoring candidate lines, including first layout.
- **HFlow and VFlow, separators and overflow:** initially lay out or resize a retained flow with
  128 tags, item separators and a two-line cap. Measurement ends when the rendered overflow indicator
  reports the expected hidden count and has a nonempty frame. Initial layout includes creating
  the content and overflow reporting hierarchy, so a resize improvement cannot conceal a slower first layout.
- **HFlow and VFlow, uncapped separators:** initially lay out or resize 128 tags with item
  separators and check the last tag's placement. This covers separator composition without a truncated tail to skip.
- **HFlow and VFlow, eight-item separators:** resize a small retained flow to distinguish fixed
  composition overhead from work that scales with child count.
- **HFlow and VFlow, overflow without separators:** initially lay out or resize the same 128
  fixed-size tags and two-line cap without separator injection. This isolates the overflow route.
- **HFlow and VFlow, cap without an indicator:** initially lay out or resize 128 fixed-size tags
  with a two-line cap and no separators. Completion checks the two-line bounds, a tag that moves
  onto the second line on resize, and the parked tail. This isolates capping without deferred overflow reporting.
- **HFlow and VFlow, line separators:** resize with line separators alone or combined with item
  separators. First-to-last tag geometry must include every 2pt divider and its spacing; an
  intermediate layout with missing dividers cannot complete the workload.
- **LazyHFlow and LazyVFlow, data growth:** grow from one item to 128 in a retained `ScrollView`.
  Measurement includes revealing and laying out enough 48pt cells to fill its 192 × 96pt viewport
  (transposed for LazyVFlow). It checks that the flow does not eagerly reveal all 128 items.

Hosted measurements use one operation per sample. They include SwiftUI updates, geometry
observations and deferred Flow reporting. Completion is checked through placed child geometry;
there is no fixed sleep in the timing. A two-second deadline fails an incomplete workload.
Retained hosts also finish priming outside measurement: the harness requires a quiet 100ms interval
without another hosting-view layout pass, then rechecks layout. This prevents deferred initial reports
from spilling into a resize sample. There is no fixed delay inside the measured update.
Hosts are detached and closed outside measurement. The windows remain offscreen; these are
layout measurements, not GPU rendering or scroll frame-rate measurements.

Three small `engine/` microbenchmarks cover greedy and balanced rigid wrapping and balanced flexible
wrapping with mixed priorities. These use `@testable import Flow` to isolate wrapping cost when
investigating a public workload regression. Enabling benchmarks makes the release library testable
without adding public interfaces. They are diagnostic measurements, not consumer performance claims.

For a focused run, or to list available workloads:

```sh
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark run --target FlowBenchmarks --filter 'public/HFlow/.*'
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark list --target FlowBenchmarks
```

Filters are regular expressions matched against the entire workload name; use `.*` for a suffix.
The default `timing` profile reports wall-clock time, CPU time, throughput and executed instructions
without enabling allocation hooks. Instruction counts help distinguish changes
in work from timing variability. Store a local baseline and compare after a change:

```sh
FLOW_BENCHMARKS=1 swift package --disable-sandbox --allow-writing-to-package-directory benchmark baseline update before --target FlowBenchmarks
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark baseline compare before --target FlowBenchmarks
```

Export results with the framework's native formats, for example:

```sh
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark run --target FlowBenchmarks --no-progress --format jmh --path stdout > /tmp/flow-benchmarks.jmh
```

Benchmark 1.38's JMH export leaves time, allocation and instruction values unnormalized. The
`engine/greedy/128` and `engine/balanced/128` workloads run 1,000 wrapping operations per
sample; divide their exported time, allocation and instruction values by 1,000 for per-operation results.
Public workloads and `engine/balanced-flexible/128` already measure one operation per sample.

Compare runs on the same host and toolchain, using the same profile. Record a fresh baseline when
changing profiles: allocation instrumentation changes execution cost. Benchmark CI publishes a report
without enforcing regression thresholds; failed or incomplete measurements still fail the reporting job.
When automating a run, check for failed workloads and missing result entries: benchmark 1.38 can
return exit status zero even when a workload reports an error.

For a 3.5.4 comparison, filter eager workloads with `public/(HFlow|VFlow)/.*`. That release does
not complete the one-to-many lazy data-growth workload because revealing does not resume when the
rendered prefix keeps the same size. Compare that workload with a version containing the lifecycle
fix; an incomplete layout is not a faster result.

## Separate timing and allocation passes

```sh
FLOW_BENCHMARKS=1 FLOW_BENCHMARK_PROFILE=allocations swift package --disable-sandbox benchmark run --target FlowBenchmarks
```

Use `FLOW_BENCHMARK_PROFILE=latency` when the host cannot provide instruction counts. It reports
CPU/wall time and throughput without requesting instructions or allocation hooks. The `timing`
profile remains strict: missing instruction results fail comparison validation. Hosted CI explicitly
uses `--profile latency,allocations` because its runner omits instruction results; its report makes
no instruction-count claim.

The allocation profile enables the allocation interposer and reports counts; its exported wall time
is instrumented and should not be used as a latency measurement. `FLOW_BENCHMARK_PROFILE=all` retains
the old combined metrics for diagnostics. `FLOW_BENCHMARK_COMPARISON=1` increases sampling from the
development budget (two warmups, 20 samples / one second) to five warmups, 100 samples / three seconds.

## Reproduce a release comparison

Run from the repository root with a Swift 6 Xcode toolchain selected:

```sh
xcrun --sdk macosx swift Benchmarks/compare.swift --baseline 3.5.4
```

The Swift runner freezes the baseline and working-tree library sources in a new temporary directory.
It copies the same current public harness and configuration into both packages, pins benchmark 1.38.0
and its dependencies with `Comparison.resolved`, and builds the measured library without `-enable-testing`.
It does not change the checkout. It runs separate timing/allocation profiles in mirrored
baseline/candidate/candidate/baseline order. No tests or other benchmarks should run concurrently.

The default filter covers all 32 eager public workloads. Options include `--candidate REF` instead of
the working tree, `--filter 'public/HFlow/separators/.*'`, `--profile timing` (or a comma-separated list),
`--repeat 3`, and `--output NEW-DIRECTORY`. `--quick` uses the development sampling budget for smoke checks.
A nonempty result directory is never overwritten. Use `--help` for the complete command syntax.

Each result directory contains frozen packages, source hashes, compiler/SDK/OS information, the exact
expected workload names, thermal states, raw JMH output and logs. Every run must have exactly the
expected workload set, unique names, finite positive metrics and medians, and unchanged dependency pins.
The runner rejects malformed exports even when benchmark exits zero. It never combines partial runs.
A failed comparison retains its raw evidence and produces no valid report; rerun into a new directory.

`report.md`, `report.csv` and `report.json` show medians across run medians, baseline/candidate deltas,
and each version's repeat spread (maximum run median divided by minimum, minus one). A large spread
limits duration claims even when instruction counts are stable. Revalidate and regenerate a saved
report with `swift Benchmarks/compare.swift --summarize RESULT-DIRECTORY`.

The independent **Benchmark report** workflow runs the same command on macOS and preserves results
as artifacts. It reports differences without a performance pass/fail threshold. The normal CI workflow
remains responsible for correctness and toolchain/platform compatibility.
