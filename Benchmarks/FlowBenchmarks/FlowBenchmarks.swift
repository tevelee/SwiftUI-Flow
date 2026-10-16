import Benchmark

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = flowBenchmarkConfiguration()
    registerPublicFlowBenchmarks()
    registerEngineBenchmarks()
}
