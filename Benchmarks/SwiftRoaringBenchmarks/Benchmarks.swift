import Benchmark

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .instructions, .mallocCountTotal],
        maxDuration: .seconds(1)
    )
    let datasets = Dataset.fetched()
    registerIteration(datasets)
    registerAddRemoveContains(datasets)
    registerSetOperations(datasets)
    registerSerialization(datasets)
}
