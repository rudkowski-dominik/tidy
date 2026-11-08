// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tidy",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Tidy", targets: ["Tidy"])
    ],
    targets: [
        .executableTarget(
            name: "Tidy",
            path: "Tidy",
            exclude: [
                "Resources/Info.plist",
                "Resources/Tidy.entitlements"
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/Localizable.xcstrings"),
                .copy("Resources/AppIconLight.png"),
                .copy("Resources/AppIconDark.png")
            ]
        ),
        .testTarget(
            name: "TidyTests",
            dependencies: ["Tidy"],
            path: "TidyTests"
        )
    ]
)
