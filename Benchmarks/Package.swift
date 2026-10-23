// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Benchmarks",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/ordo-one/benchmark", from: "1.36.0"),
        .package(name: "SwiftRoaring", path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "SwiftRoaringBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "benchmark"),
                .product(name: "SwiftRoaring", package: "SwiftRoaring"),
            ],
            path: "SwiftRoaringBenchmarks",
            plugins: [.plugin(name: "BenchmarkPlugin", package: "benchmark")]
        ),
    ]
)
