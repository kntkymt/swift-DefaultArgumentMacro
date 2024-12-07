// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "DefaultArgument",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "DefaultArgument",
            targets: ["DefaultArgument"]
        ),
        .executable(
            name: "DefaultArgumentClient",
            targets: ["DefaultArgumentClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],
    targets: [
        .macro(
            name: "DefaultArgumentMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "DefaultArgument",
            dependencies: ["DefaultArgumentMacros"]
        ),
        .executableTarget(
            name: "DefaultArgumentClient",
            dependencies: ["DefaultArgument"]
        ),
        .testTarget(
            name: "DefaultArgumentTests",
            dependencies: [
                "DefaultArgumentMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
