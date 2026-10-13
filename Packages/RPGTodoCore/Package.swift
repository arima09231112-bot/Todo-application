// swift-tools-version: 6.0
import PackageDescription

// 画面・画像・SwiftData に依存しない、純Swiftのドメインロジック。
// Linux でも `swift test` で検証できるよう、Apple 専用フレームワークを import しないこと。
let package = Package(
    name: "RPGTodoCore",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "RPGTodoCore", targets: ["RPGTodoCore"]),
    ],
    targets: [
        .target(name: "RPGTodoCore"),
        .testTarget(name: "RPGTodoCoreTests", dependencies: ["RPGTodoCore"]),
    ]
)
