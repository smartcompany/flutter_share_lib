// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "share_lib",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "share-lib", targets: ["share_lib"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "share_lib",
            dependencies: []
        )
    ]
)
