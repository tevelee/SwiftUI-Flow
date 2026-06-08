// swift-tools-version: 6.0

import Foundation
import PackageDescription

func isEnabled(_ name: String) -> Bool {
    guard let value = ProcessInfo.processInfo.environment[name] else { return false }
    return !value.isEmpty && value != "0" && value.lowercased() != "false"
}
let doccPlugin = isEnabled("FLOW_DOCC")
let propertyTesting = isEnabled("FLOW_PROPERTY_TESTING")
let snapshotTesting = isEnabled("FLOW_SNAPSHOT_TESTING")

let package = Package(
    name: "Flow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Flow", targets: ["Flow"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Flow",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "FlowTests",
            dependencies: ["Flow"],
            exclude: ["README.md"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)

let testTarget = package.targets.last!

if doccPlugin {
    package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"))
}

if propertyTesting {
    package.dependencies.append(.package(url: "https://github.com/x-sheep/swift-property-based.git", from: "1.2.0"))
    testTarget.dependencies.append(.product(name: "PropertyBased", package: "swift-property-based"))
    testTarget.swiftSettings?.append(.define("FLOW_PROPERTY_TESTING"))
} else {
    testTarget.exclude.append("PropertyTests")
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
