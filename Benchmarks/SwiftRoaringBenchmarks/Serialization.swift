import Benchmark
import SwiftRoaring

func registerSerialization(_ datasets: [Dataset]) {
    for data in datasets {
        var portable: [[Int8]] = []
        let preparePortable = {
            portable = data.bitmaps.map { bitmap in
                var bytes = [Int8](repeating: 0, count: bitmap.portableSizeInBytes())
                _ = bitmap.portableSerialize(buffer: &bytes)
                return bytes
            }
        }
        data.benchmark("frozen/portable_deserialize", prepare: preparePortable) { _ in
            blackHole(portable.reduce(0) { $0 &+ RoaringBitmap.portableDeserialize(buffer: $1).count })
        }
        data.benchmark("frozen/portable_deserialize_frozen", prepare: preparePortable) { _ in
            blackHole(portable.reduce(0) { sum, bytes in
                sum &+ bytes.withUnsafeBytes { RoaringBitmap.withPortableView(of: RawSpan(_unsafeBytes: $0)) { $0.count }! }
            })
        }
        var unsigned: [[UInt8]] = []
        let prepareUnsigned = {
            preparePortable()
            unsigned = portable.map { $0.map(UInt8.init(bitPattern:)) }
        }
        // Not in benchmark.cpp: the copying frozen API, for comparison with the borrowed view.
        data.benchmark("frozen/portable_deserialize_frozen_copy", prepare: prepareUnsigned) { _ in
            blackHole(unsigned.reduce(0) { $0 &+ RoaringBitmap.portableDeserializeFrozen(bytes: $1)!.count })
        }
    }
}
