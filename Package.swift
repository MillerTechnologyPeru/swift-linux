// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "swift-linux",
    products: [
        .library(
            name: "SwiftLinuxOS",
            targets: ["SwiftLinuxOS"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/AppRuntime.git", 
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "SwiftLinuxOS",
            dependencies: [
                "AppRuntime",
                "Buildroot"
            ]
        ),
        .target(
            name: "Buildroot",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftLinuxOSTests",
            dependencies: ["SwiftLinuxOS"]
        )
    ]
)
