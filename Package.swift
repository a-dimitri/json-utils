// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "JsonUtilities",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure logic — no SwiftUI, so it compiles fast and is unit-testable
        // without a UI or full Xcode.
        .target(name: "JSONKit"),

        // The SwiftUI app. Run with: swift run JsonUtilities
        .executableTarget(
            name: "JsonUtilities",
            dependencies: ["JSONKit"]
        ),

        // Assertion-based test runner. XCTest is unavailable under Command Line
        // Tools, so tests are a plain executable: swift run JSONKitTests
        .executableTarget(
            name: "JSONKitTests",
            dependencies: ["JSONKit"]
        ),
    ],
    // Swift 6 language mode (the default under tools-version 6.0): full strict
    // concurrency checking.
    swiftLanguageModes: [.v6]
)
