// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CloudBoost",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .target(
            name: "CloudBoostLib",
            path: "Sources/CloudBoost",
            exclude: ["App/main.swift"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "CloudBoost",
            dependencies: ["CloudBoostLib"],
            path: "Sources/CloudBoostApp",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)