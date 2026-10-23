import Benchmark
import SwiftRoaring

func registerSetOperations(_ datasets: [Dataset]) {
    for data in datasets {
        data.benchmark("microbench/SuccessiveIntersection") { _ in
            blackHole(data.pairs.reduce(0) { $0 &+ ($1.0 & $1.1).count })
        }
    }
}
