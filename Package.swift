// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftRoaring",
    products: [
        .library(name: "croaring", targets: ["croaring"]),
        .library(name: "SwiftRoaring", targets: ["SwiftRoaring"]),
        .library(name: "SwiftRoaringDynamic", type: .dynamic, targets: ["SwiftRoaring"])
    ],
    targets: [
        .target(
            name: "croaring",
            path: "./Sources/CRoaring"
        ),
        .target(
            name: "SwiftRoaring",
            dependencies: ["croaring"]
        ),
        .testTarget(
            name: "swiftRoaringTests",
            dependencies: ["SwiftRoaring"]
        )
    ]
)
