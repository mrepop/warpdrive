// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WarpDrive",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WarpDrive",
            targets: ["WarpDrive"]
        )
    ],
    dependencies: [
        // Terminal emulator
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.0.0"),
        // SSH client - we'll implement our own wrapper using Network framework and NIO
        .package(url: "https://github.com/apple/swift-nio-ssh", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.65.0"),
    ],
    targets: [
        .target(
            name: "WarpDrive",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "NIOSSH", package: "swift-nio-ssh"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            path: "WarpDrive"
        ),
        .testTarget(
            name: "WarpDriveTests",
            dependencies: ["WarpDrive"],
            path: "WarpDriveTests"
        )
    ]
)
