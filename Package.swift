// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HandGestureKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "HandGestureKit",
            targets: ["HandGestureKit"])
    ],
    targets: [
        .target(
            name: "HandGestureKit"
        )
    ],
    swiftLanguageModes: [.v5]
)
