import Benchmark

func registerIteration(_ datasets: [Dataset]) {
    for data in datasets {
        data.benchmark("microbench/IterateAll") { _ in
            var count: UInt64 = 0
            for bitmap in data.bitmaps {
                for _ in bitmap {
                    count += 1
                }
            }
            blackHole(count)
        }
        data.benchmark("iteration/previous") { _ in
            var sum: UInt64 = 0
            var iterator = data.merged.makeLastIterator()
            while let value = iterator.value {
                sum &+= UInt64(value)
                iterator.previous()
            }
            blackHole(sum)
        }
    }
}
