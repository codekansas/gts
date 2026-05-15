// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GoToSleep",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "GoToSleepCore",
            targets: ["GoToSleepCore"]
        ),
        .executable(
            name: "GoToSleep",
            targets: ["GoToSleep"]
        ),
        .executable(
            name: "GoToSleepChecks",
            targets: ["GoToSleepChecks"]
        ),
    ],
    targets: [
        .target(
            name: "GoToSleepCore"
        ),
        .executableTarget(
            name: "GoToSleep",
            dependencies: ["GoToSleepCore"]
        ),
        .executableTarget(
            name: "GoToSleepChecks",
            dependencies: ["GoToSleepCore"]
        ),
        .testTarget(
            name: "GoToSleepCoreTests",
            dependencies: ["GoToSleepCore"]
        ),
    ]
)
