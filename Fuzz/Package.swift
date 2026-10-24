// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "SwiftRoaringFuzz",
    platforms: [.macOS(.v14)],
    dependencies: [.package(name: "SwiftRoaring", path: "..")],
    targets: [
        .executableTarget(name: "SwiftRoaringFuzz", dependencies: [.product(name: "SwiftRoaring", package: "SwiftRoaring")]),
    ]
)
