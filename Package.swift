// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DHCharList",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "DHCharList", targets: ["DHCharList"])
    ],
    targets: [
        .target(name: "DHCharList"),
        .testTarget(name: "DHCharListTests", dependencies: ["DHCharList"])
    ]
)
