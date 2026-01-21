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
        // Add dependencies here as needed
    ],
    targets: [
        .target(
            name: "WarpDrive",
            dependencies: [],
            path: "WarpDrive"
        ),
        .testTarget(
            name: "WarpDriveTests",
            dependencies: ["WarpDrive"],
            path: "WarpDriveTests"
        )
    ]
)
