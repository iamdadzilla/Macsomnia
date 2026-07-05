// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeepAwake",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KeepAwakeCore"),
        .executableTarget(
            name: "KeepAwake",
            dependencies: ["KeepAwakeCore"]
        ),
        .testTarget(
            name: "KeepAwakeCoreTests",
            dependencies: ["KeepAwakeCore"]
        ),
    ]
)
