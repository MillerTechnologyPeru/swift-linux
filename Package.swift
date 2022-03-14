// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "swift-linux",
    products: [
        .executable(
            name: "swift-linux",
            targets: ["swift-linux"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/AppRuntime.git", 
            .branch("master")
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .branch("main")
        )
    ],
    targets: [
        .executableTarget(
            name: "swift-linux",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AppRuntime", package: "AppRuntime"),
                "Buildroot"
            ]
        ),
        .target(
            name: "Buildroot",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftLinuxOSTests",
            dependencies: ["Buildroot"]
        )
    ]
)
