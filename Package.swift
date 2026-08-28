// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Macsomnia",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "MacsomniaCore",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "Macsomnia",
            dependencies: ["MacsomniaCore"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "MacsomniaHelper",
            dependencies: ["MacsomniaCore"]
        ),
        .testTarget(
            name: "MacsomniaCoreTests",
            dependencies: ["MacsomniaCore"]
        ),
    ]
)
