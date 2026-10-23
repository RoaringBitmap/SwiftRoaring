import Benchmark
import Foundation
import SwiftRoaring

/// One real-roaring-datasets directory, loaded as CRoaring `benchmarks/benchmark.cpp` does.
final class Dataset {
    static let directory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("datasets")

    let name: String
    private(set) var bitmaps: [RoaringBitmap] = []
    private(set) var merged = RoaringBitmap()
    private(set) var maxValue: UInt32 = 0
    var pairs: Zip2Sequence<[RoaringBitmap], ArraySlice<RoaringBitmap>> { zip(bitmaps, bitmaps.dropFirst()) }

    private var url: URL { Self.directory.appendingPathComponent(name) }

    private init(name: String) {
        self.name = name
    }

    static func fetched() -> [Dataset] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        // fetch-datasets.sh writes `complete` last.
        let datasets = names.sorted().map(Dataset.init).filter {
            FileManager.default.fileExists(atPath: $0.url.appendingPathComponent("complete").path)
        }
        if datasets.isEmpty {
            print("No datasets in \(directory.path); run fetch-datasets.sh.")
        }
        return datasets
    }

    // Called from setup, not registration: each benchmark runs in its own process, which registers all of them.
    func load() {
        let files = try! FileManager.default.contentsOfDirectory(atPath: url.path).filter { $0.hasSuffix(".txt") }
        let values = files.sorted().map { file in
            let text = try! String(contentsOf: url.appendingPathComponent(file), encoding: .utf8)
            return text.split { $0 == "," || $0.isWhitespace }.map { UInt32($0)! }
        }
        maxValue = values.compactMap(\.last).max() ?? 0
        bitmaps = values.map(RoaringBitmap.init(values:))
        merged = RoaringBitmap()
        for bitmap in bitmaps {
            _ = bitmap.runOptimize()
            _ = bitmap.shrink()
            merged.formUnion(bitmap)
        }
    }

    func benchmark(_ name: String, prepare: @escaping () -> Void = {}, _ body: @escaping (Benchmark) -> Void) {
        Benchmark("\(name)/\(self.name)", configuration: .init(setup: { self.load(); prepare() }), closure: body)
    }
}
