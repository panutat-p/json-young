// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "json-swift",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "json-linter", targets: ["JSONLinter"])
    ],
    targets: [
        .target(
            name: "JSONLinterLib",
            path: "Sources/JSONLinterLib"
        ),
        .executableTarget(
            name: "JSONLinter",
            dependencies: ["JSONLinterLib"],
            path: "Sources/JSONLinter"
        ),
        .testTarget(
            name: "JSONLinterTests",
            dependencies: ["JSONLinterLib"],
            path: "Tests/JSONLinterTests"
        )
    ]
)
