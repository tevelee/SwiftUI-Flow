// swift-tools-version: 5.9

import Foundation
import PackageDescription

func isEnabled(_ name: String) -> Bool {
    guard let value = ProcessInfo.processInfo.environment[name] else { return false }
    return !value.isEmpty && value != "0" && value.lowercased() != "false"
}
let doccPlugin = isEnabled("FLOW_DOCC")
let snapshotTesting = isEnabled("FLOW_SNAPSHOT_TESTING")

let package = Package(
    name: "Flow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        // Umbrella: the core engine plus every feature target.
        .library(name: "Flow", targets: ["Flow", "FlowLineLimit", "FlowSeparators"]),
        // The feature-free layout engine on its own.
        .library(name: "FlowCore", targets: ["Flow"]),
        // Individually composable features, each usable without the other.
        .library(name: "FlowLineLimit", targets: ["FlowLineLimit"]),
        .library(name: "FlowSeparators", targets: ["FlowSeparators"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Flow",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "FlowLineLimit",
            dependencies: ["Flow"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "FlowSeparators",
            dependencies: ["Flow"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FlowTests",
            dependencies: ["Flow", "FlowLineLimit", "FlowSeparators"],
            exclude: [
                "README.md",
                "PropertyTests"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)

let testTarget = package.targets.last!

if doccPlugin {
    package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"))
}

if snapshotTesting {
    package.dependencies.append(.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.19.0"))
    testTarget.dependencies.append(.product(name: "SnapshotTesting", package: "swift-snapshot-testing"))
    testTarget.dependencies.append(.product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"))
    testTarget.swiftSettings?.append(.define("FLOW_SNAPSHOT_TESTING"))
    testTarget.exclude.append("SnapshotTests/Image/__Snapshots__")
} else {
    testTarget.exclude.append("SnapshotTests")
}
