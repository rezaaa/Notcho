// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NotchTasks",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "NotchTasks", targets: ["NotchTasks"])
    ],
    dependencies: [
        .package(url: "https://github.com/MrKai77/DynamicNotchKit", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "NotchTasks",
            dependencies: [
                .product(name: "DynamicNotchKit", package: "DynamicNotchKit")
            ]
        )
    ]
)
