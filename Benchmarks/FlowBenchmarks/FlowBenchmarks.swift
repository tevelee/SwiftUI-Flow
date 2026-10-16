import Benchmark

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .cpuTotal, .throughput, .mallocCountTotal, .instructions],
        warmupIterations: 2,
        scalingFactor: .one,
        maxDuration: .seconds(1),
        maxIterations: 20
    )
    registerPublicFlowBenchmarks()
    registerEngineBenchmarks()
}
