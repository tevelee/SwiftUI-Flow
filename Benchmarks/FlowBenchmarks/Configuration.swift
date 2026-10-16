import Benchmark
import Foundation

/// Keep timing separate from the allocation interposer; combined metrics remain available for diagnostics.
func flowBenchmarkConfiguration() -> Benchmark.Configuration {
    let environment = ProcessInfo.processInfo.environment
    let profile = environment["FLOW_BENCHMARK_PROFILE"] ?? "timing"
    let metrics: [BenchmarkMetric]
    switch profile {
        case "timing": metrics = [.wallClock, .cpuTotal, .throughput, .instructions]
        case "allocations": metrics = [.wallClock, .throughput, .mallocCountTotal]
        case "all": metrics = [.wallClock, .cpuTotal, .throughput, .mallocCountTotal, .instructions]
        default: preconditionFailure("Unknown FLOW_BENCHMARK_PROFILE: \(profile)")
    }
    let comparison = environment["FLOW_BENCHMARK_COMPARISON"] == "1"
    return .init(
        metrics: metrics,
        warmupIterations: comparison ? 5 : 2,
        scalingFactor: .one,
        maxDuration: .seconds(comparison ? 3 : 1),
        maxIterations: comparison ? 100 : 20
    )
}
