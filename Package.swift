// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Serial",
    platforms: [
        .macOS(.v10_10)
    ],
    products: [
        .library(name: "Serial", targets: ["Serial"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Serial", dependencies: []),
        .testTarget(name: "SerialTests", dependencies: ["Serial"]),
    ]
)
