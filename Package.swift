// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Movia",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Movia",
            targets: ["Movia"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Movia",
            dependencies: [],
            path: "Sources/Movia"
        )
    ]
)
