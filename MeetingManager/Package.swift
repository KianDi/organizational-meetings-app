// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MeetingManager",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MeetingManager",
            targets: ["MeetingManager"])
    ],
    dependencies: [
        // Dependencies will be added in later phases as needed
        // Phase 1: Keep minimal - no external dependencies yet
    ],
    targets: [
        .target(
            name: "MeetingManager",
            dependencies: [])
    ]
)
