// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IgniteStarter",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/twostraws/Ignite.git", branch: "main"),
        // Imported directly by ArticleMarkdownRenderer (Ignite also uses it).
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.7.3"),
    ],
    targets: [
        .executableTarget(
            name: "IgniteStarter",
            dependencies: [
                "Ignite",
                .product(name: "Markdown", package: "swift-markdown"),
            ]),
        .testTarget(
            name: "IgniteStarterTests",
            dependencies: ["IgniteStarter"]),
    ]
)
