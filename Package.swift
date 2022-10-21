// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "Flow", targets: ["Flow"]),
        .executable(name: "Renderer", targets: ["Renderer"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .target(name: "Flow", dependencies: []),
        .testTarget(name: "FlowTests", dependencies: ["Flow"]),
        .executableTarget(name: "Renderer", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .target(name: "Flow")
        ]),
    ]
)
