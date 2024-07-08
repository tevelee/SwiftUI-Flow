// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "Flow", targets: ["Flow"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(name: "Flow", exclude: ["Example"], swiftSettings: [.swiftLanguageVersion(.v6)]),
        .testTarget(name: "FlowTests", dependencies: ["Flow"], swiftSettings: [.swiftLanguageVersion(.v6)])
    ]
)
