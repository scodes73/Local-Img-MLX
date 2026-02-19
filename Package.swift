// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LocalImg",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-examples/", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "LocalImg",
            dependencies: [
                .product(name: "StableDiffusion", package: "mlx-swift-examples"),
            ],
            path: "Sources/LocalImg",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/LocalImg/Info.plist",
                ]),
            ]
        ),
    ]
)
