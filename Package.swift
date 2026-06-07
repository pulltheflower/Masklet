// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SensitivePasteGuard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SensitivePasteGuard", targets: ["SensitivePasteGuard"])
    ],
    targets: [
        .executableTarget(
            name: "SensitivePasteGuard",
            path: "Sources/SensitivePasteGuard"
        ),
        .testTarget(
            name: "SensitivePasteGuardTests",
            dependencies: ["SensitivePasteGuard"],
            path: "Tests/SensitivePasteGuardTests"
        )
    ]
)
