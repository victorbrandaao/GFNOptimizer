// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GFNOptimizer",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(name: "GFNOptimizer")
    ]
)