// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MemeManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MemeManager", targets: ["MemeManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.14.1")
    ],
    targets: [
        .executableTarget(
            name: "MemeManager",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "MemeManager",
            resources: [
                .copy("Resources/MemeManager.entitlements")
            ]
        )
    ]
)