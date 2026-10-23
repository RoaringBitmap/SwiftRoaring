import Benchmark
import SwiftRoaring

func registerAddRemoveContains(_ datasets: [Dataset]) {
    Benchmark("roaring_bitmap/create_free", configuration: .init(scalingFactor: .kilo)) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(RoaringBitmap())
        }
    }

    func addBenchmark(_ name: String, full: Bool, _ body: @escaping (RoaringBitmap, [UInt32]) -> Void) {
        Benchmark("roaring_bitmap/\(name)", configuration: .init(setup: { _ = addBenchmarkOffsets })) { benchmark in
            let offsets = addBenchmarkOffsets[name]!
            let bitmap = RoaringBitmap()
            if full {
                bitmap.addRange(min: 0, max: 1_000_000)
            }
            benchmark.startMeasurement()
            body(bitmap, offsets)
            benchmark.stopMeasurement()
        }
    }
    addBenchmark("add/intvlen=1/order=shuffle", full: false) { bitmap, offsets in
        for offset in offsets {
            bitmap.add(offset)
        }
    }
    addBenchmark("remove/intvlen=1/order=shuffle", full: true) { bitmap, offsets in
        for offset in offsets {
            bitmap.discard(offset)
        }
    }

    for data in datasets {
        data.benchmark("microbench/RandomAccess") { _ in
            let max = data.maxValue
            var marks = 0
            for bitmap in data.bitmaps {
                marks &+= bitmap.contains(max / 4) ? 1 : 0
                marks &+= bitmap.contains(max / 2) ? 1 : 0
                marks &+= bitmap.contains(3 &* max / 4) ? 1 : 0 // C's uint32_t wraps
            }
            blackHole(marks)
        }
    }
}

// benchmark.cpp draws every variant from one pcg32 in this order; replaying all reproduces the C inputs.
let addBenchmarkOffsets: [String: [UInt32]] = {
    let span: UInt32 = 1_000_000
    var random = PCG32()
    var offsets: [String: [UInt32]] = [:]
    for order in ["shuffle", "asc"] {
        for length: UInt32 in [1, 16] {
            for algorithm in ["add", "add_many", "add_bulk", "add_range", "remove", "remove_range"] {
                // benchmark.cpp make_data: intervals fill 20% of the span.
                let count = Int((Double(span) * 0.2 / Double(length)).rounded(.down))
                var values = (0..<count).map { _ in random.next() }
                let sum = values.reduce(UInt64(0)) { $0 + UInt64($1) }
                for i in values.indices {
                    var gap = Double(values[i])
                    gap /= Double(sum)
                    gap *= Double(span - UInt32(count) * length) / Double(length)
                    values[i] = (i == 0 ? 0 : values[i - 1] + length) + UInt32(gap.rounded(.down))
                }
                if order == "shuffle" {
                    random.shuffle(&values)
                }
                offsets["\(algorithm)/intvlen=\(length)/order=\(order)"] = values
            }
        }
    }
    return offsets
}()
