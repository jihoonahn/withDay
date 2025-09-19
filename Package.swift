// swift-tools-version: 6.1
import PackageDescription

let products: [Product] = [
    .executable(
        name: "generate",
        targets: ["Generate"]
    ),
    .executable(
        name: "clean",
        targets: ["Clean"]
    ),
    .executable(
        name: "module",
        targets: ["Module"]
    ),
    .executable(
        name: "install",
        targets: ["Install"]
    ),
    .executable(
        name: "uninstall",
        targets: ["Uninstall"]
    )
]

let package = Package(
    name: "designtuist-command",
    platforms: [.macOS(.v13)],
    products: products,
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.3"),
        .package(url: "https://github.com/pelagornis/swift-command", from: "1.3.1"),
        .package(url: "https://github.com/pelagornis/swift-file", from: "1.2.3"),
        .package(url: "https://github.com/pelagornis/swift-cli", from: "0.1.2"),
    ],
    targets: [
        .executableTarget(
            name: "Module",
            dependencies: ["CommandKit"],
            path: "Commands/Module"
        ),
        .executableTarget(
            name: "Install",
            dependencies: ["CommandKit"],
            path: "Commands/Install"
        ),
        .executableTarget(
            name: "Uninstall",
            dependencies: ["CommandKit"],
            path: "Commands/Uninstall"
        ),
        .executableTarget(
            name: "Clean",
            dependencies: ["CommandKit"],
            path: "Commands/Clean"
        ),
        .executableTarget(
            name: "Generate",
            dependencies: ["CommandKit"],
            path: "Commands/Generate"
        ),
        .target(
            name: "CommandKit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CommandLine", package: "swift-cli"),
                .product(name: "Command", package: "swift-command"),
                .product(name: "File", package: "swift-file"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Commands/CommandKit"
        )
    ]
)
