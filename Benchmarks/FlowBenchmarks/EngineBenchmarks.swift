import Benchmark
import Foundation

@testable import Flow

// Diagnostic measurements only: consumer-facing results live in PublicFlowBenchmarks.swift.
func registerEngineBenchmarks() {
    for mode in ["greedy", "balanced", "balanced-flexible"] {
        let balanced = mode != "greedy"
        let flexible = mode == "balanced-flexible"
        var configuration = Benchmark.defaultConfiguration
        configuration.scalingFactor = flexible ? .one : .kilo
        configuration.maxIterations = 100
        Benchmark("engine/\(mode)/128", configuration: configuration) { benchmark in
            let items = (0 ..< 128).map { index in
                let breadth = CGFloat(24 + (index % 7) * 8)
                return MeasuredItem(size: breadth ... (flexible ? breadth * 3 : breadth), spacing: 4, priority: flexible ? Double(index % 3) : 0)
            }
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                if balanced {
                    blackHole(KnuthPlassLineBreaker().wrapItemsToLines(items: items, in: flexible ? 480 : 320))
                } else {
                    blackHole(GreedyLineBreaker().wrapItemsToLines(items: items, in: 320))
                }
            }
            benchmark.stopMeasurement()
        }
    }
}
