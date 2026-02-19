// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Notcho",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Notcho", targets: ["Notcho"])
    ],
    dependencies: [
        .package(path: "LocalPackages/DynamicNotchKit"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.7.0")
    ],
    targets: [
        .executableTarget(
            name: "Notcho",
            dependencies: [
                .product(name: "DynamicNotchKit", package: "DynamicNotchKit"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/AppCore",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
