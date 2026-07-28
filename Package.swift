// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "MarathiDeep",
    platforms: [.macOS(.v12)],
    products: [
        .executable(
            name: "MarathiDeep",
            targets: ["MarathiDeep"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Publish.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "MarathiDeep",
            dependencies: ["Publish"]
        )
    ]
)
