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
    }
}
