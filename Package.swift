// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "serial",
    platforms: [
        .macOS(.v10_10)
    ],
    products: [
        .library(name: "serial", targets: ["serial"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "serial", dependencies: []),
        .testTarget(name: "serialTests", dependencies: ["serial"]),
    ]
)
