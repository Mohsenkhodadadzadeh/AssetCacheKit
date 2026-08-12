// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AssetCacheKit",
    platforms: [
        .iOS(.v13),
        // Every public symbol is annotated `@available(macOS 12.0, ...)` and the
        // README advertises macOS 12+. Declaring .v14 here contradicted both and
        // made the package unresolvable for macOS 12/13 consumers.
        .macOS(.v12),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AssetCacheKit",
            targets: ["AssetCacheKit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AssetCacheKit"),
        .testTarget(
            name: "AssetCacheKitTests",
            dependencies: ["AssetCacheKit"]
        ),
    ]
)
