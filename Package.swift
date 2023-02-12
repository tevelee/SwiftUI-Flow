// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "Flow", targets: ["Flow"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Flow", dependencies: []),
        .testTarget(name: "FlowTests", dependencies: ["Flow"]),
    ]
)
