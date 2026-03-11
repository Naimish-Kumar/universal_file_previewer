// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "universal_file_previewer",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "universal-file-previewer", targets: ["universal_file_previewer"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "universal_file_previewer",
            dependencies: [],
            path: "Classes",
            resources: []
        )
    ]
)
