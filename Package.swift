// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlanBridgeCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PlanBridgeCore", targets: ["PlanBridgeCore"])],
    targets: [
        .target(name: "PlanBridgeCore"),
        .testTarget(name: "PlanBridgeCoreTests", dependencies: ["PlanBridgeCore"])
    ]
)
