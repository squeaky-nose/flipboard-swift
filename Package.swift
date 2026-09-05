// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlipboardSwift",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FlipboardSwift",
            targets: ["FlipboardSwift"]
        ),
    ],
    dependencies: [
        // Local path for active development alongside flipboard-swift-protocol, mirroring the same
        // dev-time arrangement used in flipboard-apple. flipboard-swift is published independently
        // and consumed remotely elsewhere, so this must switch to a versioned remote reference
        // before flipboard-swift itself is tagged/released again.
        .package(path: "../flipboard-swift-protocol"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FlipboardSwift",
            dependencies: [
                .product(name: "FlipboardSwiftProtocol", package: "flipboard-swift-protocol"),
            ]
        ),
        .testTarget(
            name: "FlipboardSwiftTests",
            dependencies: ["FlipboardSwift"]
        ),
    ]
)
