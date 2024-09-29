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
    targets: [
        .target(
            name: "Flow",
            exclude: ["Example"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "FlowTests",
            dependencies: ["Flow"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
