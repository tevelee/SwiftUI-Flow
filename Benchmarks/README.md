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

Ten hosted workloads exercise the public interface with ordinary `import Flow`:

- **HFlow and VFlow, initial text layout:** create and attach an `NSHostingView` containing 128
  text tags, then complete layout. Window and model creation happen outside measurement.
- **HFlow and VFlow, text resizing:** retain the hosting view and change the available breadth
  from 320pt to 180pt. Priming happens outside measurement; the timed update must change placement.
- **HFlow and VFlow, balanced flexible resizing:** resize 128 flexible tags from 960pt to 480pt
  with `distributeItemsEvenly`. This exercises candidate sizing as well as choosing line breaks.
- **HFlow and VFlow, separators and overflow:** resize a retained flow with 128 tags, item
  separators and a two-line cap. Measurement ends when the rendered overflow indicator reports
  the expected new hidden count and has a nonempty frame.
- **LazyHFlow and LazyVFlow, data growth:** grow from one item to 128 in a retained `ScrollView`.
  Measurement includes revealing and laying out enough 48pt cells to fill its 192 × 96pt viewport
  (transposed for LazyVFlow). It checks that the flow does not eagerly reveal all 128 items.

Hosted measurements use one operation per sample. They include SwiftUI updates, geometry
observations and deferred Flow reporting. Completion is checked through placed child geometry;
there is no fixed sleep in the timing. A two-second deadline fails an incomplete workload.
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
All workloads report wall-clock time, CPU time, throughput and allocations using the framework's
warmup and percentile reporting. Store a local baseline and compare after a change:

```sh
FLOW_BENCHMARKS=1 swift package --disable-sandbox --allow-writing-to-package-directory benchmark baseline update before --target FlowBenchmarks
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark baseline compare before --target FlowBenchmarks
```

Export results with the framework's native formats, for example:

```sh
FLOW_BENCHMARKS=1 swift package --disable-sandbox benchmark run --target FlowBenchmarks --no-progress --format jmh --path stdout > /tmp/flow-benchmarks.jmh
```

Benchmark 1.38's JMH export leaves time and allocation values unnormalized. The
`engine/greedy/128` and `engine/balanced/128` workloads run 1,000 wrapping operations per
sample; divide their exported time and allocation values by 1,000 for per-operation results.
Public workloads and `engine/balanced-flexible/128` already measure one operation per sample.

Compare runs on the same host and toolchain. No performance thresholds or benchmark CI gates are
configured. These workload names replace the earlier internal matrix; record a fresh baseline.
When automating a run, check for failed workloads and missing result entries: benchmark 1.38 can
return exit status zero even when a workload reports an error.
