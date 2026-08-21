import XCTest
@testable import SwiftRoaring

class roaring64Tests: XCTestCase {
    var rbm: Roaring64Bitmap!

    /// A few values spread over several high-48-bit partitions.
    let spread: [UInt64] = [
        0,
        1,
        1 << 16,
        1 << 32,
        (1 << 32) + 1,
        1 << 48,
        UInt64.max
    ]

    override func setUp() {
        super.setUp()
        rbm = Roaring64Bitmap()
    }

    func testAddContainsRemove() {
        for value in spread {
            rbm.add(value)
        }
        XCTAssertEqual(rbm.count, UInt64(spread.count))
        for value in spread {
            XCTAssertTrue(rbm.contains(value))
        }
        XCTAssertFalse(rbm.contains(2))
        XCTAssertEqual(rbm.remove(1 << 32), 1 << 32)
        XCTAssertNil(rbm.remove(1 << 32))
        XCTAssertFalse(rbm.contains(1 << 32))
    }

    func testArrayLiteralAndValues() {
        let a: Roaring64Bitmap = [3, 1, 2, 1]
        XCTAssertEqual(a.toArray(), [1, 2, 3])
        XCTAssertEqual(Roaring64Bitmap(values: spread).toArray(), spread.sorted())
    }

    func testDiscard() {
        let a: Roaring64Bitmap = [1, 2, 1 << 40]
        a.discard(2)
        a.discard(99)
        XCTAssertEqual(a.toArray(), [1, 1 << 40])
    }

    func testAddManyRemoveMany() {
        rbm.addMany(values: spread)
        XCTAssertEqual(rbm.count, UInt64(spread.count))
        rbm.removeMany(values: [0, 1, UInt64.max])
        XCTAssertEqual(rbm.toArray(), [1 << 16, 1 << 32, (1 << 32) + 1, 1 << 48])
    }

    func testAddCheckedAndUpdate() {
        XCTAssertTrue(rbm.addCheck(7))
        XCTAssertFalse(rbm.addCheck(7))
        XCTAssertEqual(rbm.update(with: 7), 7)
        XCTAssertNil(rbm.update(with: 8))
    }

    func testRanges() {
        rbm.add(10...20)
        XCTAssertEqual(rbm.count, 11)
        XCTAssertTrue(rbm.contains(10...20))
        XCTAssertTrue(rbm.contains(10..<21))
        XCTAssertFalse(rbm.contains(10...21))
        XCTAssertEqual(rbm.cardinality(in: 12...14), 3)
        XCTAssertEqual(rbm.cardinality(in: 12..<14), 2)
        XCTAssertEqual(rbm.rangeCardinality(min: 0, max: 15), 5)
        XCTAssertEqual(rbm.rangeCardinalityClosed(min: 0, max: 15), 6)

        rbm.remove(12...14)
        XCTAssertEqual(rbm.toArray(), [10, 11, 15, 16, 17, 18, 19, 20])
        rbm.remove(15..<17)
        XCTAssertEqual(rbm.toArray(), [10, 11, 17, 18, 19, 20])

        XCTAssertTrue(rbm.intersects(0..<11))
        XCTAssertFalse(rbm.intersects(0..<10))
        XCTAssertFalse(rbm.intersectWithRange(min: 12, max: 17))
    }

    func testInitRange() {
        let a = Roaring64Bitmap(min: 0, max: 1000, step: 50)
        XCTAssertEqual(a.toArray(), Array(stride(from: UInt64(0), to: 1000, by: 50)))
        let b = Roaring64Bitmap(range: 0..<1000, step: 50)
        XCTAssertEqual(a, b)
        // An empty or degenerate range yields an empty bitmap rather than crashing.
        XCTAssertTrue(Roaring64Bitmap(min: 10, max: 10, step: 1).isEmpty)
        XCTAssertTrue(Roaring64Bitmap(min: 0, max: 10, step: 0).isEmpty)
    }

    func testSetOperations() {
        let a: Roaring64Bitmap = [1, 2, 3, 1 << 40]
        let b: Roaring64Bitmap = [3, 4, 1 << 40]

        XCTAssertEqual((a & b).toArray(), [3, 1 << 40])
        XCTAssertEqual((a | b).toArray(), [1, 2, 3, 4, 1 << 40])
        XCTAssertEqual((a ^ b).toArray(), [1, 2, 4])
        XCTAssertEqual((a - b).toArray(), [1, 2])

        XCTAssertEqual(a.intersectionCount(b), 2)
        XCTAssertEqual(a.unionCount(b), 5)
        XCTAssertEqual(a.symmetricDifferenceCount(b), 3)
        XCTAssertEqual(a.subtractingCount(b), 2)
        XCTAssertEqual(a.jaccardIndex(b), 2.0 / 5.0)

        XCTAssertTrue(a.intersect(b))
        XCTAssertFalse(a.isDisjoint(with: b))
        XCTAssertTrue(a.isDisjoint(with: [5, 6] as Roaring64Bitmap))

        let sub: Roaring64Bitmap = [1, 2]
        XCTAssertTrue(sub.isSubset(of: a))
        XCTAssertTrue(sub.isStrictSubset(of: a))
        XCTAssertFalse(a.isStrictSubset(of: a))
        XCTAssertTrue(a.isSubset(of: a))
    }

    func testInPlaceSetOperations() {
        let a: Roaring64Bitmap = [1, 2, 3]
        a &= [2, 3, 4]
        XCTAssertEqual(a.toArray(), [2, 3])
        a |= [9]
        XCTAssertEqual(a.toArray(), [2, 3, 9])
        a ^= [3, 10]
        XCTAssertEqual(a.toArray(), [2, 9, 10])
        a -= [9]
        XCTAssertEqual(a.toArray(), [2, 10])
    }

    func testFlip() {
        let a: Roaring64Bitmap = [1, 3]
        XCTAssertEqual(a.flip(0..<4).toArray(), [0, 2])
        XCTAssertEqual(a.flip(0...3).toArray(), [0, 2])
        XCTAssertEqual(a.flip(rangeStart: 0, rangeEnd: 4).toArray(), [0, 2])
        XCTAssertEqual(a.flipClosed(rangeStart: 0, rangeEnd: 3).toArray(), [0, 2])
        // The originals are untouched.
        XCTAssertEqual(a.toArray(), [1, 3])

        let b: Roaring64Bitmap = [1, 3]
        b.flipInPlace(0..<4)
        XCTAssertEqual(b.toArray(), [0, 2])
        b.flipInPlace(0...3)
        XCTAssertEqual(b.toArray(), [1, 3])
        b.flipInplace(rangeStart: 0, rangeEnd: 4)
        XCTAssertEqual(b.toArray(), [0, 2])
        b.flipInplaceClosed(rangeStart: 0, rangeEnd: 3)
        XCTAssertEqual(b.toArray(), [1, 3])
    }

    func testOffsets() {
        let a: Roaring64Bitmap = [1, 2, 1 << 40]
        XCTAssertEqual(a.addOffset(10).toArray(), [11, 12, (1 << 40) + 10])
        XCTAssertEqual(a.subtractOffset(1).toArray(), [0, 1, (1 << 40) - 1])
        // Values that would underflow are dropped.
        XCTAssertEqual(a.subtractOffset(2).toArray(), [0, (1 << 40) - 2])
    }

    func testCopyAndOverwrite() {
        let a: Roaring64Bitmap = [1, 2, 1 << 40]
        let b = a.copy()
        XCTAssertEqual(a, b)
        b.add(3)
        XCTAssertNotEqual(a, b)

        let c: Roaring64Bitmap = [99]
        c.overwrite(with: a)
        XCTAssertEqual(c, a)
    }

    func testMinMaxRankSelectIndex() {
        let a: Roaring64Bitmap = [1, 5, 1 << 40]
        XCTAssertEqual(a.min(), 1)
        XCTAssertEqual(a.max(), 1 << 40)
        XCTAssertEqual(a.first, 1)
        XCTAssertEqual(a.last, 1 << 40)

        XCTAssertEqual(a.rank(value: 5), 2)
        XCTAssertEqual(a.rank(value: 4), 1)

        XCTAssertEqual(a.select(rank: 0), 1)
        XCTAssertEqual(a.select(rank: 2), 1 << 40)
        XCTAssertNil(a.select(rank: 3))

        XCTAssertEqual(a.index(of: 5), 1)
        XCTAssertEqual(a.index(of: 1 << 40), 2)
        XCTAssertNil(a.index(of: 6))

        let empty = Roaring64Bitmap()
        XCTAssertNil(empty.min())
        XCTAssertNil(empty.max())
    }

    func testPopFirstPopLast() {
        let a: Roaring64Bitmap = [1, 2, 1 << 40]
        XCTAssertEqual(a.popFirst(), 1)
        XCTAssertEqual(a.popLast(), 1 << 40)
        XCTAssertEqual(a.popFirst(), 2)
        XCTAssertNil(a.popFirst())
        XCTAssertNil(a.popLast())
        XCTAssertTrue(a.isEmpty)
    }

    func testClearAndRemoveAllWhere() {
        rbm.addMany(values: spread)
        rbm.removeAll { $0 < (1 << 32) }
        XCTAssertEqual(rbm.toArray(), [1 << 32, (1 << 32) + 1, 1 << 48, UInt64.max])
        rbm.removeAll()
        XCTAssertTrue(rbm.isEmpty)
    }

    func testSequenceIteration() {
        rbm.addMany(values: spread)
        XCTAssertEqual(Array(rbm), spread.sorted())
        XCTAssertTrue(rbm.elementsEqual(spread.sorted()))
    }

    func testIteratorNavigation() {
        let a = Roaring64Bitmap(values: spread)

        let forward = a.makeIterator()
        XCTAssertTrue(forward.hasValue)
        XCTAssertEqual(forward.currentValue, 0)
        XCTAssertEqual(forward.value, 0)
        XCTAssertTrue(forward.advance())
        XCTAssertEqual(forward.value, 1)

        let fork = forward.copy()
        XCTAssertTrue(fork.advance())
        XCTAssertEqual(fork.value, 1 << 16)
        // The fork moved independently.
        XCTAssertEqual(forward.value, 1)

        XCTAssertTrue(forward.previous())
        XCTAssertEqual(forward.value, 0)
        XCTAssertFalse(forward.previous())
        XCTAssertNil(forward.value)

        forward.reinit()
        XCTAssertEqual(forward.value, 0)
        forward.reinitLast()
        XCTAssertEqual(forward.value, UInt64.max)

        let backward = a.makeLastIterator()
        var reversed: [UInt64] = []
        while let value = backward.nextBackward() {
            reversed.append(value)
        }
        XCTAssertEqual(reversed, spread.sorted().reversed())

        let seek = a.makeIterator()
        XCTAssertTrue(seek.moveEqualOrLarger(1 << 32))
        XCTAssertEqual(seek.value, 1 << 32)
        XCTAssertTrue(seek.moveEqualOrLarger(UInt64.max - 1))
        XCTAssertEqual(seek.value, UInt64.max)
        XCTAssertFalse(seek.advance())
    }

    func testIteratorRead() {
        let a = Roaring64Bitmap(values: spread)
        let it = a.makeIterator()
        XCTAssertEqual(it.read(count: 3), [0, 1, 1 << 16])
        // Asking for more than what is left yields a shorter array.
        XCTAssertEqual(it.read(count: 100), [1 << 32, (1 << 32) + 1, 1 << 48, UInt64.max])
        XCTAssertEqual(it.read(count: 1), [])

        let back = a.makeLastIterator()
        XCTAssertEqual(back.readBackward(count: 2), [UInt64.max, 1 << 48])
    }

    func testIteratorReadRanges() {
        let a: Roaring64Bitmap = [1, 2, 3, 5, 6, 100]
        let it = a.makeIterator()
        XCTAssertEqual(it.readRanges(count: 2), [1...3, 5...6])
        XCTAssertEqual(it.readRanges(count: 10), [100...100])
        XCTAssertEqual(it.readRanges(count: 10), [])

        let back = a.makeLastIterator()
        XCTAssertEqual(back.readPreviousRanges(count: 2), [100...100, 5...6])
    }

    func testClosureIteration() {
        let a = Roaring64Bitmap(values: spread)
        var seen: [UInt64] = []
        XCTAssertTrue(a.iterate { seen.append($0); return true })
        XCTAssertEqual(seen, spread.sorted())

        var partial: [UInt64] = []
        XCTAssertFalse(a.iterate { partial.append($0); return partial.count < 3 })
        XCTAssertEqual(partial, Array(spread.sorted().prefix(3)))
    }

    func testBulkContext() {
        var context = Roaring64Bitmap.BulkContext()
        for value in spread.sorted() {
            rbm.addBulk(value, context: &context)
        }
        XCTAssertEqual(rbm.toArray(), spread.sorted())

        context.reset()
        for value in spread.sorted() {
            XCTAssertTrue(rbm.containsBulk(value, context: &context))
        }

        context.reset()
        rbm.removeBulk(1 << 32, context: &context)
        XCTAssertFalse(rbm.contains(1 << 32))
    }

    func testOptimizationAndStatistics() {
        rbm.add(0...10_000)
        XCTAssertTrue(rbm.runOptimize())
        XCTAssertGreaterThan(rbm.statistics().n_run_containers, 0)
        _ = rbm.shrink()
        XCTAssertTrue(rbm.removeRunCompression())
        XCTAssertEqual(rbm.statistics().n_run_containers, 0)
        XCTAssertEqual(rbm.statistics().cardinality, 10_001)
        XCTAssertNil(rbm.internalValidate())
    }

    func testPortableSerialization() {
        rbm.addMany(values: spread)
        let bytes = rbm.portableSerialize()
        XCTAssertEqual(bytes.count, rbm.portableSizeInBytes())

        let back = Roaring64Bitmap.portableDeserializeSafe(bytes: bytes)
        XCTAssertEqual(back, rbm)

        // Truncated input is rejected rather than crashing.
        XCTAssertNil(Roaring64Bitmap.portableDeserializeSafe(bytes: Array(bytes.prefix(3))))

        var buffer = [Int8](repeating: 0, count: rbm.portableSizeInBytes())
        XCTAssertEqual(rbm.portableSerialize(buffer: &buffer), buffer.count)
        XCTAssertEqual(
            Roaring64Bitmap.portableDeserializeSize(buffer: buffer, maxbytes: buffer.count),
            buffer.count
        )
        XCTAssertEqual(
            Roaring64Bitmap.portableDeserializeSafe(buffer: buffer, maxbytes: buffer.count),
            rbm
        )
    }

    func testFrozenSerialization() {
        rbm.addMany(values: spread)
        rbm.add(1000...2000)
        _ = rbm.shrink()

        let bytes = rbm.frozenSerialize()
        XCTAssertEqual(bytes.count, rbm.frozenSizeInBytes())

        guard let view = Roaring64Bitmap.frozenView(bytes: bytes) else {
            return XCTFail("frozen view could not be created")
        }
        XCTAssertEqual(view, rbm)
        XCTAssertEqual(view.toArray(), rbm.toArray())
    }

    func testEmptyBitmapRoundTrips() {
        let empty = Roaring64Bitmap()
        _ = empty.shrink()

        guard let frozen = Roaring64Bitmap.frozenView(bytes: empty.frozenSerialize()) else {
            return XCTFail("frozen view of an empty bitmap could not be created")
        }
        XCTAssertTrue(frozen.isEmpty)

        XCTAssertEqual(
            Roaring64Bitmap.portableDeserializeSafe(bytes: empty.portableSerialize())?.isEmpty,
            true
        )
        XCTAssertEqual(empty.toArray(), [])
        XCTAssertNil(empty.select(rank: 0))
        XCTAssertNil(empty.index(of: 0))
        XCTAssertTrue(empty.iterate { _ in true })
        XCTAssertNil(empty.makeIterator().next())
        XCTAssertNil(empty.makeLastIterator().nextBackward())
    }

    func testCodable() throws {
        rbm.addMany(values: spread)
        let encoded = try JSONEncoder().encode(rbm)
        let decoded = try JSONDecoder().decode(Roaring64Bitmap.self, from: encoded)
        XCTAssertEqual(decoded, rbm)

        let garbage = try JSONEncoder().encode("not a bitmap")
        XCTAssertThrowsError(try JSONDecoder().decode(Roaring64Bitmap.self, from: garbage))
    }

    func testFromRoaringBitmap() {
        let source: RoaringBitmap = [1, 2, 3]

        let copied = Roaring64Bitmap(source)
        XCTAssertEqual(copied.toArray(), [1, 2, 3])
        // The 32-bit source keeps its values.
        XCTAssertEqual(source.toArray(), [1, 2, 3])

        let moved = Roaring64Bitmap(moving: source)
        XCTAssertEqual(moved.toArray(), [1, 2, 3])
        XCTAssertTrue(source.isEmpty)
    }

    func testHashableAndDescription() {
        let a: Roaring64Bitmap = [1, 2, 3]
        let b: Roaring64Bitmap = [1, 2, 3]
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertEqual(Set([a, b]).count, 1)
        XCTAssertEqual(a.description, "Roaring64Bitmap(1, 2, 3)")

        let big = Roaring64Bitmap(range: 0..<200, step: 1)
        XCTAssertTrue(big.description.hasSuffix(", ...)"))
    }
}
