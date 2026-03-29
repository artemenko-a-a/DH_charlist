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
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.6.0")
    ],
    targets: [
        .target(name: "DHCharList"),
        .testTarget(
            name: "DHCharListTests",
            dependencies: [
                "DHCharList",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
