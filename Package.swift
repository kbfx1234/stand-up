// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StandUp",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "StandUpCore", targets: ["StandUpCore"]),
        .executable(name: "StandUp", targets: ["StandUp"])
    ],
    targets: [
        .target(name: "StandUpCore", path: "Core"),
        .executableTarget(
            name: "StandUp",
            dependencies: ["StandUpCore"],
            path: "Sources/StandUp"
        ),
        .testTarget(
            name: "StandUpTests",
            dependencies: ["StandUpCore"],
            path: "Tests"
        )
    ]
)
