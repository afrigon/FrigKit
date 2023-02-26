// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "FrigKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16)
    ],
    products: [
        .library(name: "FrigKit", targets: ["FrigKit"]),
        .library(name: "FrigKitNetwork", targets: ["FrigKitNetwork"]),
        .library(name: "FrigKitTestUtil", targets: ["FrigKitTestUtil"]),
        .library(name: "FrigKitUI", targets: ["FrigKitUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", exact: "11.3.0"),
        .package(url: "https://github.com/Quick/Nimble.git", exact: "10.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.10.0")
    ],
    targets: [
        .target(
            name: "FrigKit",
            path: "src/Core"
        ),

        .target(
            name: "FrigKitNetwork",
            dependencies: [
                "FrigKit"
            ],
            path: "src/Network"
        ),

        .target(
            name: "FrigKitTestUtil",
            dependencies: [
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "src/TestUtil"
        ),

        .target(
            name: "FrigKitUI",
            dependencies: [
                .product(name: "NukeUI", package: "Nuke")
            ],
            path: "src/UI"
        ),

        .testTarget(
            name: "FrigKitTests",
            dependencies: [
                "FrigKit",
                "FrigKitNetwork",
                "FrigKitTestUtil",
                "FrigKitUI"
            ],
            path: "tests"
        )
    ]
)
