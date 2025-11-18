// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HappyLaunderer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "HappyLaunderer",
            targets: ["HappyLaunderer"]),
    ],
    dependencies: [
        // Clerk SDK for authentication
        // Note: Add this package via Xcode -> File -> Add Packages
        // URL: https://github.com/clerk/clerk-ios
    ],
    targets: [
        .target(
            name: "HappyLaunderer",
            dependencies: []),
        .testTarget(
            name: "HappyLaundererTests",
            dependencies: ["HappyLaunderer"]),
    ]
)

