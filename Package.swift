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
        .package(path: "LocalPackages/DynamicNotchKit")
    ],
    targets: [
        .executableTarget(
            name: "NotchTasks",
            dependencies: [
                .product(name: "DynamicNotchKit", package: "DynamicNotchKit")
            ],
            path: "Sources/NotchTasks"
        )
    ]
)
