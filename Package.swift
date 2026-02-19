// swift-tools-version:5.9
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
        .package(url: "https://github.com/MrKai77/DynamicNotchKit.git", revision: "36e728b91fec43d3427a846497f5b1735e539153"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "NotchTasks",
            dependencies: [
                .product(name: "DynamicNotchKit", package: "dynamicnotchkit"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/NotchTasks"
        )
    ]
)
