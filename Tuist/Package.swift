// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "Rex": .framework,
            // 충돌 방지를 위해 SPM 'Network' 제품을 정적 라이브러리로 빌드
            "Network": .staticLibrary
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "DEV"),
                .debug(name:  "STAGE"),
                .release(name: "PROD")
            ]
        )
    )
#endif

let package = Package(
    name: "Package",
    dependencies: [
        .package(url: "https://github.com/pelagornis/swift-rex", .upToNextMajor(from: "0.1.1")),
        .package(url: "https://github.com/pelagornis/refineui-system-icons", from: "0.3.17"),
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.32.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.4"),
    ]
)
