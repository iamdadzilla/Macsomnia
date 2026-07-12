// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Macsomnia",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "MacsomniaCore"),
        .executableTarget(
            name: "Macsomnia",
            dependencies: ["MacsomniaCore"]
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
