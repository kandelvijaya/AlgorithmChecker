// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "AlgoChecker",
    products: [
        .library(
            name: "AlgoChecker",
            targets: ["AlgoChecker"]),
    ],
    dependencies: [ ],
    targets: [
        .target(
            name: "AlgoChecker",
            dependencies: []),
        .testTarget(
            name: "AlgoCheckerTests",
            dependencies: ["AlgoChecker"]),
    ]
)
