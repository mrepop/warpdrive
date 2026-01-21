// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WarpDrive",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WarpDriveCore",
            targets: ["WarpDriveCore"]
        )
    ],
    dependencies: [
        // Terminal emulator
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0"),
        // SSH client - high-level interface over NIO-SSH for iOS/macOS
        .package(url: "https://github.com/orlandos-nl/Citadel", from: "0.11.0"),
    ],
    targets: [
        .target(
            name: "WarpDriveCore",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "Citadel", package: "Citadel"),
            ],
            path: "WarpDrive",
            exclude: ["App", "Info.plist", "Resources"]
        ),
        .testTarget(
            name: "WarpDriveTests",
            dependencies: ["WarpDriveCore"],
            path: "WarpDriveTests"
        )
    ]
)
