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
        // Phase 2: Authentication system with Supabase
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "MeetingManager",
            dependencies: [])
    ]
)
