#!/usr/bin/env swift
import CryptoKit
import Foundation

struct ComparisonError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description = description }
}

struct Options {
    var baseline = "3.5.4"
    var candidate = "working-tree"
    var filter = "public/(HFlow|VFlow)/.*"
    var profiles = ["timing", "allocations"]
    var repeats = 2
    var quick = false
    var output = FileManager.default.temporaryDirectory.appendingPathComponent("flow-comparison-\(UUID().uuidString)")
    var summarize: URL?

    init() throws {
        var arguments = Array(CommandLine.arguments.dropFirst())
        while !arguments.isEmpty {
            let flag = arguments.removeFirst()
            if flag == "--quick" {
                quick = true
                continue
            }
            if flag == "--help" {
                print(
                    """
                    swift Benchmarks/compare.swift [--baseline REF] [--candidate REF|working-tree]
                        [--profile timing|allocations|all|both] [--filter FULL-NAME-REGEX]
                        [--repeat N] [--output NEW-DIRECTORY] [--quick]
                    swift Benchmarks/compare.swift --summarize RESULT-DIRECTORY
                    Default: 3.5.4 versus working tree, eager public workloads, two mirrored repeats,
                    separate timing/allocation passes. --quick uses the development sampling budget.
                    A nonempty output directory is never overwritten. No performance threshold is enforced.
                    """
                )
                exit(0)
            }
            guard !arguments.isEmpty else { throw ComparisonError("Missing value for \(flag)") }
            let value = arguments.removeFirst()
            switch flag {
                case "--baseline": baseline = value
                case "--candidate": candidate = value
                case "--filter": filter = value
                case "--repeat":
                    guard let number = Int(value), number >= 2 else { throw ComparisonError("--repeat must be at least two") }
                    repeats = number
                case "--profile":
                    guard value == "both" || value.split(separator: ",").allSatisfy({ ["timing", "allocations", "all"].contains(String($0)) }) else {
                        throw ComparisonError("Unknown profile \(value)")
                    }
                    profiles = value == "both" ? ["timing", "allocations"] : value.split(separator: ",").map(String.init)
                    guard !profiles.isEmpty, Set(profiles).count == profiles.count else { throw ComparisonError("Profiles must be nonempty and unique") }
                case "--output": output = URL(fileURLWithPath: value).standardizedFileURL
                case "--summarize": summarize = URL(fileURLWithPath: value).standardizedFileURL
                default: throw ComparisonError("Unknown option \(flag)")
            }
        }
    }
}

let files = FileManager.default
let options: Options
do { options = try Options() } catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

@discardableResult
func command(_ executable: String, _ arguments: [String], at directory: URL, environment: [String: String] = [:], stdout: URL, stderr: URL) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = directory
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
    files.createFile(atPath: stdout.path, contents: nil)
    files.createFile(atPath: stderr.path, contents: nil)
    let output = try FileHandle(forWritingTo: stdout)
    let errors = try FileHandle(forWritingTo: stderr)
    defer {
        try? output.close()
        try? errors.close()
    }
    process.standardOutput = output
    process.standardError = errors
    try process.run()
    process.waitUntilExit()
    return process.terminationStatus
}

func textCommand(_ executable: String, _ arguments: [String], at directory: URL) throws -> String {
    let temporary = files.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let errors = temporary.appendingPathExtension("stderr")
    defer {
        try? files.removeItem(at: temporary)
        try? files.removeItem(at: errors)
    }
    guard try command(executable, arguments, at: directory, stdout: temporary, stderr: errors) == 0 else {
        throw ComparisonError("Command failed: \(executable) \(arguments.joined(separator: " "))\n\(try String(contentsOf: errors, encoding: .utf8))")
    }
    return try String(contentsOf: temporary, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
}

func writeJSON(_ value: some Encodable, to path: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(value).write(to: path)
}

struct Run: Codable {
    var profile: String
    var variant: String
    var index: Int
    var prefix: String
    var thermalState: Int
}

struct Manifest: Codable {
    var baseline: String
    var candidate: String
    var repositoryHEAD: String
    var compiler: String
    var sdk: String
    var operatingSystem: String
    var filter: String
    var quick: Bool
    var expected: [String]
    var profiles: [String]
    var sourceHashes: [String: [String: String]]
    var runs: [Run]
}

struct Metric: Decodable {
    var score: Double
    var scoreUnit: String
    var scorePercentiles: [String: Double]
}

struct Result: Decodable {
    var benchmark: String
    var secondaryMetrics: [String: Metric]
}

func metrics(for profile: String) -> [String] {
    switch profile {
        case "timing": ["Time (wall clock)", "Time (total CPU)", "Instructions"]
        case "allocations": ["Malloc (total)"]
        default: ["Time (wall clock)", "Time (total CPU)", "Instructions", "Malloc (total)"]
    }
}

func validatedResults(_ run: Run, manifest: Manifest, at output: URL) throws -> [String: Result] {
    let path = output.appendingPathComponent(run.prefix + ".jmh.json")
    guard let data = try? Data(contentsOf: path), let rows = try? JSONDecoder().decode([Result].self, from: data) else {
        throw ComparisonError("Rejected invalid/incomplete JMH output: \(path.path). Inspect the matching .log; exit zero is insufficient.")
    }
    var results: [String: Result] = [:]
    for row in rows {
        guard let start = row.benchmark.range(of: "public/") else { throw ComparisonError("Unexpected benchmark \(row.benchmark)") }
        let name = String(row.benchmark[start.lowerBound...])
        guard results.updateValue(row, forKey: name) == nil else { throw ComparisonError("Duplicate result \(name)") }
        for metric in metrics(for: run.profile) {
            guard let value = row.secondaryMetrics[metric], value.score.isFinite, value.score > 0,
                let median = value.scorePercentiles["50.0"], median.isFinite, median > 0
            else { throw ComparisonError("Missing/invalid \(metric) for \(name) in \(run.prefix)") }
        }
        if run.profile == "timing", row.secondaryMetrics["Malloc (total)"] != nil {
            throw ComparisonError("Timing pass unexpectedly enabled allocation instrumentation")
        }
    }
    guard Set(results.keys) == Set(manifest.expected) else {
        throw ComparisonError("Incomplete workload set in \(run.prefix): expected \(manifest.expected.count), got \(results.count)")
    }
    return results
}

struct Summary: Codable {
    var workload: String
    var profile: String
    var metric: String
    var unit: String
    var baseline: Double
    var candidate: Double
    var changePercent: Double
    var baselineRepeatSpreadPercent: Double
    var candidateRepeatSpreadPercent: Double
}

func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    return (sorted[(sorted.count - 1) / 2] + sorted[sorted.count / 2]) / 2
}

func spread(_ values: [Double]) -> Double { (values.max()! / values.min()! - 1) * 100 }

func summarize(at output: URL) throws {
    // Revalidation must never leave a stale success report after corrupt/incomplete raw results.
    for name in ["report.md", "report.csv", "report.json"] {
        let path = output.appendingPathComponent(name)
        if files.fileExists(atPath: path.path) { try files.removeItem(at: path) }
    }
    let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: output.appendingPathComponent("manifest.json")))
    let results = try manifest.runs.map { try validatedResults($0, manifest: manifest, at: output) }
    var summaries: [Summary] = []
    for profile in manifest.profiles {
        let baselineRuns = manifest.runs.indices.filter { manifest.runs[$0].profile == profile && manifest.runs[$0].variant == "baseline" }
        let candidateRuns = manifest.runs.indices.filter { manifest.runs[$0].profile == profile && manifest.runs[$0].variant == "candidate" }
        guard baselineRuns.count >= 2, baselineRuns.count == candidateRuns.count else { throw ComparisonError("Missing mirrored repeats for \(profile)") }
        for name in manifest.expected {
            for metric in metrics(for: profile) {
                let baseline = baselineRuns.map { results[$0][name]!.secondaryMetrics[metric]!.scorePercentiles["50.0"]! }
                let candidate = candidateRuns.map { results[$0][name]!.secondaryMetrics[metric]!.scorePercentiles["50.0"]! }
                let unit = results[baselineRuns[0]][name]!.secondaryMetrics[metric]!.scoreUnit
                guard
                    manifest.runs.indices.filter({ manifest.runs[$0].profile == profile }).allSatisfy({
                        results[$0][name]!.secondaryMetrics[metric]!.scoreUnit == unit
                    })
                else {
                    throw ComparisonError("Metric units changed for \(name), \(metric)")
                }
                summaries.append(
                    Summary(
                        workload: name,
                        profile: profile,
                        metric: metric,
                        unit: unit,
                        baseline: median(baseline),
                        candidate: median(candidate),
                        changePercent: (median(candidate) / median(baseline) - 1) * 100,
                        baselineRepeatSpreadPercent: spread(baseline),
                        candidateRepeatSpreadPercent: spread(candidate)
                    )
                )
            }
        }
    }
    try writeJSON(summaries, to: output.appendingPathComponent("report.json"))
    func csv(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
    let csvRows = summaries.map {
        [
            $0.workload, $0.profile, $0.metric, $0.unit, String($0.baseline), String($0.candidate), String($0.changePercent),
            String($0.baselineRepeatSpreadPercent), String($0.candidateRepeatSpreadPercent),
        ].map(csv).joined(separator: ",")
    }
    try (["workload,profile,metric,unit,baseline,candidate,change_percent,baseline_repeat_spread_percent,candidate_repeat_spread_percent"] + csvRows).joined(
        separator: "\n"
    ).appending("\n").write(to: output.appendingPathComponent("report.csv"), atomically: true, encoding: .utf8)
    var markdown = "# Public Flow benchmark comparison\n\nBaseline: `\(manifest.baseline)`. Candidate: `\(manifest.candidate)`.\n\n"
    markdown +=
        "\(manifest.expected.count) completed workloads per run. Values are medians of run medians. Positive deltas mean more time/work; repeat spread is max/min minus one. Timing excludes allocation hooks; allocation-pass wall time is not a latency result. No regression threshold is enforced.\n\n"
    markdown += "| Workload | Profile / metric | Baseline | Candidate | Change | Repeat spread, base / candidate |\n|---|---|---:|---:|---:|---:|\n"
    for row in summaries {
        markdown +=
            "| \(row.workload) | \(row.profile) / \(row.metric) | \(String(format: "%.1f", row.baseline)) \(row.unit) | \(String(format: "%.1f", row.candidate)) \(row.unit) | \(String(format: "%+.1f%%", row.changePercent)) | \(String(format: "%.1f%% / %.1f%%", row.baselineRepeatSpreadPercent, row.candidateRepeatSpreadPercent)) |\n"
    }
    try markdown.write(to: output.appendingPathComponent("report.md"), atomically: true, encoding: .utf8)
    print("Validated report: \(output.appendingPathComponent("report.md").path)")
}

func runComparison() throws {
    if let output = options.summarize {
        try summarize(at: output)
        return
    }
    let root = URL(fileURLWithPath: try textCommand("/usr/bin/git", ["rev-parse", "--show-toplevel"], at: URL(fileURLWithPath: files.currentDirectoryPath)))
    let output = options.output.resolvingSymlinksInPath().standardizedFileURL
    guard
        !["Sources", "Benchmarks", ".git"].contains(where: {
            let path = root.appendingPathComponent($0).resolvingSymlinksInPath().path
            return output.path == path || output.path.hasPrefix(path + "/")
        })
    else { throw ComparisonError("Output must be outside Sources, Benchmarks and .git") }
    guard !files.fileExists(atPath: output.path) else { throw ComparisonError("Output already exists: \(output.path). Choose a new directory.") }
    try files.createDirectory(at: output.appendingPathComponent("raw"), withIntermediateDirectories: true)
    let baseline = try textCommand("/usr/bin/git", ["rev-parse", "--verify", "--end-of-options", "\(options.baseline)^{commit}"], at: root)
    let candidate =
        options.candidate == "working-tree"
        ? "working-tree" : try textCommand("/usr/bin/git", ["rev-parse", "--verify", "--end-of-options", "\(options.candidate)^{commit}"], at: root)
    let head = try textCommand("/usr/bin/git", ["rev-parse", "HEAD"], at: root)
    let harness = root.appendingPathComponent("Benchmarks/FlowBenchmarks")
    let lock = root.appendingPathComponent("Benchmarks/Comparison.resolved")
    let expression = try NSRegularExpression(pattern: "^(?:\(options.filter))$")
    var hashes: [String: [String: String]] = [:]
    var expected: [String] = []
    func pins(_ path: URL) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: path)) as? [String: Any]
        guard let pins = object?["pins"] as? [[String: Any]] else { throw ComparisonError("Missing dependency lock pins") }
        return try JSONSerialization.data(withJSONObject: pins, options: [.sortedKeys])
    }
    for (variant, revision) in [("baseline", baseline), ("candidate", candidate)] {
        let package = output.appendingPathComponent("packages/\(variant)")
        try files.createDirectory(at: package.appendingPathComponent("Benchmarks/FlowBenchmarks"), withIntermediateDirectories: true)
        if revision == "working-tree" {
            try files.copyItem(at: root.appendingPathComponent("Sources"), to: package.appendingPathComponent("Sources"))
            let status = try textCommand("/usr/bin/git", ["status", "--short", "--", "Sources", "Benchmarks"], at: root)
            try status.write(to: output.appendingPathComponent("working-tree-status.txt"), atomically: true, encoding: .utf8)
            try textCommand("/usr/bin/git", ["diff", "--binary", "HEAD", "--", "Sources", "Benchmarks"], at: root).write(
                to: output.appendingPathComponent("candidate.patch"),
                atomically: true,
                encoding: .utf8
            )
        } else {
            let archive = package.appendingPathComponent("sources.tar")
            guard
                try command(
                    "/usr/bin/git",
                    ["archive", "--format=tar", revision, "Sources"],
                    at: root,
                    stdout: archive,
                    stderr: package.appendingPathComponent("archive.log")
                ) == 0,
                try command(
                    "/usr/bin/tar",
                    ["-xf", archive.path],
                    at: package,
                    stdout: package.appendingPathComponent("extract.log"),
                    stderr: package.appendingPathComponent("extract-error.log")
                ) == 0
            else { throw ComparisonError("Could not export \(revision)") }
            try files.removeItem(at: archive)
        }
        for file in ["PublicFlowBenchmarks.swift", "Configuration.swift"] {
            try files.copyItem(at: harness.appendingPathComponent(file), to: package.appendingPathComponent("Benchmarks/FlowBenchmarks/\(file)"))
        }
        try
            "import Benchmark\nlet benchmarks: @Sendable () -> Void = {\n    Benchmark.defaultConfiguration = flowBenchmarkConfiguration()\n    registerPublicFlowBenchmarks()\n}\n"
            .write(to: package.appendingPathComponent("Benchmarks/FlowBenchmarks/FlowBenchmarks.swift"), atomically: true, encoding: .utf8)
        try """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(
            name: "FlowReleaseComparison",
            platforms: [.macOS(.v14)],
            dependencies: [.package(url: "https://github.com/ordo-one/benchmark", exact: "1.38.0")],
            targets: [
                .target(name: "Flow", swiftSettings: [.enableUpcomingFeature("ExistentialAny"), .swiftLanguageMode(.v6)]),
                .executableTarget(name: "FlowBenchmarks", dependencies: ["Flow", .product(name: "Benchmark", package: "benchmark")], path: "Benchmarks/FlowBenchmarks", swiftSettings: [.enableUpcomingFeature("ExistentialAny"), .swiftLanguageMode(.v6)], plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")])
            ])
        """.write(to: package.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try files.copyItem(at: lock, to: package.appendingPathComponent("Package.resolved"))
        let list = package.appendingPathComponent("list.txt")
        guard
            try command(
                "/usr/bin/xcrun",
                ["--sdk", "macosx", "swift", "package", "--disable-sandbox", "benchmark", "list", "--target", "FlowBenchmarks"],
                at: package,
                environment: ["FLOW_BENCHMARK_PROFILE": "timing"],
                stdout: list,
                stderr: package.appendingPathComponent("list.log")
            ) == 0
        else {
            throw ComparisonError("Cannot enumerate \(variant) benchmarks; inspect \(package.path)/list.log")
        }
        guard try pins(lock) == pins(package.appendingPathComponent("Package.resolved")) else { throw ComparisonError("Dependency pins changed in \(variant)") }
        let names = try String(contentsOf: list, encoding: .utf8).split(separator: "\n").map(String.init).filter { name in
            name.hasPrefix("public/") && expression.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
        }.sorted()
        guard !names.isEmpty, Set(names).count == names.count, variant == "baseline" || expected == names else {
            throw ComparisonError("Empty, duplicate, or mismatched benchmark inventory")
        }
        expected = names
        let paths = ["Sources", "Benchmarks"].flatMap { directory in
            files.enumerator(at: package.appendingPathComponent(directory), includingPropertiesForKeys: nil)!
                .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        }
        hashes[variant] = try Dictionary(
            uniqueKeysWithValues: paths.map {
                ($0.path.replacingOccurrences(of: package.path + "/", with: ""), SHA256.hash(data: try Data(contentsOf: $0)).description)
            }
        )
    }
    var runs: [Run] = []
    for profile in options.profiles {
        for repeatIndex in 0 ..< options.repeats {
            for variant in repeatIndex.isMultiple(of: 2) ? ["baseline", "candidate"] : ["candidate", "baseline"] {
                runs.append(Run(profile: profile, variant: variant, index: repeatIndex, prefix: "raw/\(profile)-\(runs.count)-\(variant)", thermalState: -1))
            }
        }
    }
    var manifest = Manifest(
        baseline: baseline,
        candidate: candidate,
        repositoryHEAD: head,
        compiler: try textCommand("/usr/bin/xcrun", ["--sdk", "macosx", "swift", "--version"], at: root),
        sdk: try textCommand("/usr/bin/xcrun", ["--sdk", "macosx", "--show-sdk-version"], at: root),
        operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
        filter: options.filter,
        quick: options.quick,
        expected: expected,
        profiles: options.profiles,
        sourceHashes: hashes,
        runs: runs
    )
    let manifestPath = output.appendingPathComponent("manifest.json")
    try writeJSON(manifest, to: manifestPath)
    for index in manifest.runs.indices {
        manifest.runs[index].thermalState = ProcessInfo.processInfo.thermalState.rawValue
        let run = manifest.runs[index]
        try writeJSON(manifest, to: manifestPath)
        print("\(Date()) \(index + 1)/\(runs.count): \(run.profile), \(run.variant), \(expected.count) workloads; thermal=\(run.thermalState)")
        fflush(stdout)
        let package = output.appendingPathComponent("packages/\(run.variant)")
        let status = try command(
            "/usr/bin/xcrun",
            [
                "--sdk", "macosx", "swift", "package", "--disable-sandbox", "benchmark", "run", "--target", "FlowBenchmarks", "--filter", options.filter,
                "--no-progress", "--format", "jmh", "--path", "stdout",
            ],
            at: package,
            environment: ["FLOW_BENCHMARK_PROFILE": run.profile, "FLOW_BENCHMARK_COMPARISON": options.quick ? "0" : "1"],
            stdout: output.appendingPathComponent(run.prefix + ".jmh.json"),
            stderr: output.appendingPathComponent(run.prefix + ".log")
        )
        guard status == 0 else { throw ComparisonError("Benchmark process failed (\(status)); inspect \(run.prefix).log. No partial results accepted.") }
        _ = try validatedResults(run, manifest: manifest, at: output)
        guard try pins(lock) == pins(package.appendingPathComponent("Package.resolved")) else {
            throw ComparisonError("Dependency pins changed during measurement")
        }
    }
    try summarize(at: output)
}

do {
    try runComparison()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
