import PackageDescription

let package = Package(
    name: "SwiftRoaring",
    targets: [
        Target(name: "SwiftRoaring", dependencies: ["CRoaring"]),
    ])