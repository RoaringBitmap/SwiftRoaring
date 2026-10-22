// CRoaring benchmarks/random.h; draws must match it exactly to reproduce benchmark.cpp inputs.
struct PCG32 {
    private var state: UInt64 = 0x853C_49E6_748F_EA9B
    private let inc: UInt64 = 0xDA3E_39CB_94B9_5BDB

    mutating func next() -> UInt32 {
        let old = state
        state = old &* 6_364_136_223_846_793_005 &+ inc
        let xorshifted = UInt32(truncatingIfNeeded: ((old >> 18) ^ old) >> 27)
        let rot = UInt32(truncatingIfNeeded: old >> 59)
        return (xorshifted >> rot) | (xorshifted << ((0 &- rot) & 31))
    }

    // ranged_random.
    mutating func ranged(_ range: UInt32) -> UInt32 {
        var random = UInt64(next())
        if range & (range &- 1) == 0 {
            return UInt32(truncatingIfNeeded: random) & (range &- 1)
        }
        if range > 0x8000_0000 {
            while random >= range {
                random = UInt64(next())
            }
            return UInt32(random)
        }
        var product = random &* UInt64(range)
        if UInt32(truncatingIfNeeded: product) < range {
            let threshold = UInt32.max % range
            while UInt32(truncatingIfNeeded: product) <= threshold {
                random = UInt64(next())
                product = random &* UInt64(range)
            }
        }
        return UInt32(product >> 32)
    }

    // shuffle_uint32.
    mutating func shuffle(_ array: inout [UInt32]) {
        var i = UInt32(array.count)
        while i > 1 {
            array.swapAt(Int(i) - 1, Int(ranged(i)))
            i -= 1
        }
    }
}
