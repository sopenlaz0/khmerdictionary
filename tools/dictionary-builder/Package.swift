// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dictionary-builder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "DictionaryBuilderCore", targets: ["DictionaryBuilderCore"]),
        .executable(name: "dictionary-builder", targets: ["dictionary-builder"])
    ],
    targets: [
        .target(
            name: "DictionaryBuilderCore"
        ),
        .executableTarget(
            name: "dictionary-builder",
            dependencies: ["DictionaryBuilderCore"]
        ),
        .testTarget(
            name: "DictionaryBuilderCoreTests",
            dependencies: ["DictionaryBuilderCore"]
        )
    ]
)
