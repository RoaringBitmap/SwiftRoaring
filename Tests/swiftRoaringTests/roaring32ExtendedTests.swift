import XCTest
@testable import SwiftRoaring

///
/// Covers the 32-bit C functions that the original wrapper left out.
///
class roaring32ExtendedTests: XCTestCase {

    func testBulkContext() {
        let a = RoaringBitmap()
        var context = RoaringBitmap.BulkContext()
        for value in stride(from: UInt32(0), to: 1000, by: 3) {
            a.addBulk(value, context: &context)
        }
        XCTAssertEqual(a.toArray(), Array(stride(from: UInt32(0), to: 1000, by: 3)))

        context.reset()
        for value in stride(from: UInt32(0), to: 1000, by: 3) {
            XCTAssertTrue(a.containsBulk(value, context: &context))
        }
        context.reset()
        XCTAssertFalse(a.containsBulk(1, context: &context))
    }

    func testOverwrite() {
        let a: RoaringBitmap = [1, 2, 3]
        let b: RoaringBitmap = [99]
        XCTAssertTrue(b.overwrite(with: a))
        XCTAssertEqual(b.toArray(), [1, 2, 3])
        // The source is untouched, and the two are independent.
        b.add(4)
        XCTAssertEqual(a.toArray(), [1, 2, 3])
    }

    func testDiscard() {
        let a: RoaringBitmap = [1, 2, 3]
        a.discard(2)
        a.discard(99)
        XCTAssertEqual(a.toArray(), [1, 3])
    }

    func testRemoveMany() {
        let a = RoaringBitmap(range: 0..<10, step: 1)
        a.removeMany(values: [0, 2, 4, 100])
        XCTAssertEqual(a.toArray(), [1, 3, 5, 6, 7, 8, 9])
    }

    func testRemoveRangeSugar() {
        let a = RoaringBitmap(range: 0..<10, step: 1)
        a.remove(2...4)
        XCTAssertEqual(a.toArray(), [0, 1, 5, 6, 7, 8, 9])
        a.remove(5..<8)
        XCTAssertEqual(a.toArray(), [0, 1, 8, 9])
    }

    func testContainsAndCardinalityRanges() {
        let a = RoaringBitmap(range: 10..<21, step: 1)
        XCTAssertTrue(a.contains(10...20))
        XCTAssertTrue(a.containsRangeClosed(min: 10, max: 20))
        XCTAssertFalse(a.contains(10...21))

        XCTAssertEqual(a.cardinality(in: 12...14), 3)
        XCTAssertEqual(a.cardinality(in: 12..<14), 2)
        XCTAssertEqual(a.rangeCardinalityClosed(min: 0, max: 15), 6)
        XCTAssertEqual(a.rangeCardinality(min: 0, max: 15), 5)
    }

    func testIntersectWithRange() {
        let a: RoaringBitmap = [10, 20, 30]
        XCTAssertTrue(a.intersectWithRange(min: 0, max: 11))
        XCTAssertFalse(a.intersectWithRange(min: 0, max: 10))
        XCTAssertTrue(a.intersects(20..<21))
        XCTAssertFalse(a.intersects(21..<30))
    }

    func testFlipClosed() {
        let a: RoaringBitmap = [1, 3]
        XCTAssertEqual(a.flipClosed(rangeStart: 0, rangeEnd: 3).toArray(), [0, 2])
        XCTAssertEqual(a.flip(0...3).toArray(), [0, 2])
        XCTAssertEqual(a.toArray(), [1, 3])

        let b: RoaringBitmap = [1, 3]
        b.flipInplaceClosed(rangeStart: 0, rangeEnd: 3)
        XCTAssertEqual(b.toArray(), [0, 2])
        b.flipInPlace(0...3)
        XCTAssertEqual(b.toArray(), [1, 3])
    }

    func testAddOffset() {
        let a: RoaringBitmap = [1, 2, 3]
        XCTAssertEqual(a.addOffset(10).toArray(), [11, 12, 13])
        XCTAssertEqual(a.addOffset(-1).toArray(), [0, 1, 2])
        // Values that would fall outside UInt32 are dropped.
        XCTAssertEqual(a.addOffset(-2).toArray(), [0, 1])
    }

    func testSelect() {
        let a: RoaringBitmap = [10, 20, 30]
        XCTAssertEqual(a.select(rank: 0), 10)
        XCTAssertEqual(a.select(rank: 2), 30)
        XCTAssertNil(a.select(rank: 3))
    }

    func testRankMany() {
        let a: RoaringBitmap = [1, 5, 9]
        XCTAssertEqual(a.rankMany([0, 1, 5, 6, 9, 100]), [0, 1, 2, 2, 3, 3])
        XCTAssertEqual(a.rankMany([]), [])
    }

    func testIndexOf() {
        let a: RoaringBitmap = [10, 20, 30]
        XCTAssertEqual(a.index(of: 10), 0)
        XCTAssertEqual(a.index(of: 30), 2)
        XCTAssertNil(a.index(of: 11))
    }

    func testCopyOnWrite() {
        let a = RoaringBitmap(range: 0..<1000, step: 1)
        XCTAssertFalse(a.copyOnWrite)
        XCTAssertFalse(a.containsShared)

        a.copyOnWrite = true
        XCTAssertTrue(a.copyOnWrite)

        let b = a.copy()
        XCTAssertTrue(a.containsShared)
        XCTAssertTrue(b.containsShared)
        XCTAssertEqual(a, b)

        XCTAssertTrue(b.unshareAll())
        XCTAssertFalse(b.containsShared)

        a.copyOnWrite = false
        XCTAssertFalse(a.copyOnWrite)
        XCTAssertFalse(a.containsShared)
        XCTAssertEqual(a, b)
    }

    func testIterate() {
        let a = RoaringBitmap(range: 0..<100, step: 7)
        var seen: [UInt32] = []
        XCTAssertTrue(a.iterate { seen.append($0); return true })
        XCTAssertEqual(seen, Array(stride(from: UInt32(0), to: 100, by: 7)))

        var partial: [UInt32] = []
        XCTAssertFalse(a.iterate { partial.append($0); return partial.count < 3 })
        XCTAssertEqual(partial, [0, 7, 14])
    }

    func testIterate64() {
        let a: RoaringBitmap = [1, 2, 3]
        var seen: [UInt64] = []
        XCTAssertTrue(a.iterate64(highBits: 1 << 32) { seen.append($0); return true })
        XCTAssertEqual(seen, [(1 << 32) + 1, (1 << 32) + 2, (1 << 32) + 3])
    }

    func testIteratorNavigation() {
        let a: RoaringBitmap = [1, 2, 3, 5, 6, 100]

        var forward = a.makeIterator()
        XCTAssertTrue(forward.hasValue)
        XCTAssertEqual(forward.currentValue, 1)
        XCTAssertEqual(forward.value, 1)
        XCTAssertTrue(forward.advance())
        XCTAssertEqual(forward.value, 2)

        // The iterator is a value type: the copy moves on its own.
        var fork = forward
        XCTAssertTrue(fork.advance())
        XCTAssertEqual(fork.value, 3)
        XCTAssertEqual(forward.value, 2)

        XCTAssertTrue(forward.previous())
        XCTAssertEqual(forward.value, 1)
        XCTAssertFalse(forward.previous())
        XCTAssertNil(forward.value)

        var seek = a.makeIterator()
        XCTAssertTrue(seek.moveEqualOrLarger(4))
        XCTAssertEqual(seek.value, 5)
        XCTAssertFalse(seek.moveEqualOrLarger(101))

        var backward = a.makeLastIterator()
        var reversed: [UInt32] = []
        while let value = backward.nextBackward() {
            reversed.append(value)
        }
        XCTAssertEqual(reversed, [100, 6, 5, 3, 2, 1])
    }

    func testIteratorRead() {
        let a = RoaringBitmap(range: 0..<10, step: 1)
        var it = a.makeIterator()
        XCTAssertEqual(it.read(count: 3), [0, 1, 2])
        XCTAssertEqual(it.read(count: 100), [3, 4, 5, 6, 7, 8, 9])
        XCTAssertEqual(it.read(count: 1), [])

        var back = a.makeLastIterator()
        XCTAssertEqual(back.readBackward(count: 3), [9, 8, 7])
    }

    func testIteratorSkip() {
        let a = RoaringBitmap(range: 0..<10, step: 1)
        var it = a.makeIterator()
        XCTAssertEqual(it.skip(4), 4)
        XCTAssertEqual(it.value, 4)
        XCTAssertEqual(it.skip(100), 6)
        XCTAssertNil(it.value)

        var back = a.makeLastIterator()
        XCTAssertEqual(back.skipBackward(4), 4)
        XCTAssertEqual(back.value, 5)
    }

    func testIteratorReadRanges() {
        let a: RoaringBitmap = [1, 2, 3, 5, 6, 100]
        var it = a.makeIterator()
        XCTAssertEqual(it.readRanges(count: 2), [1...3, 5...6])
        XCTAssertEqual(it.readRanges(count: 10), [100...100])
        XCTAssertEqual(it.readRanges(count: 10), [])

        var back = a.makeLastIterator()
        XCTAssertEqual(back.readPreviousRanges(count: 2), [100...100, 5...6])
    }

    func testToArrayPaged() {
        let a = RoaringBitmap(range: 0..<100, step: 1)
        XCTAssertEqual(a.toArray(offset: 0, limit: 3), [0, 1, 2])
        XCTAssertEqual(a.toArray(offset: 97, limit: 10), [97, 98, 99])
        XCTAssertEqual(a.toArray(offset: 100, limit: 10), [])
    }

    func testToBitsetWords() {
        let a: RoaringBitmap = [0, 1, 63, 64, 130]
        guard let words = a.toBitsetWords() else {
            return XCTFail("could not build the bitset")
        }
        XCTAssertGreaterThanOrEqual(words.count, 3)
        for value in a {
            let word = words[Int(value / 64)]
            XCTAssertEqual((word >> (UInt64(value) % 64)) & 1, 1)
        }
        XCTAssertEqual(words.reduce(0) { $0 + $1.nonzeroBitCount }, 5)
        // An empty bitmap has no bit set, whatever the number of words.
        XCTAssertEqual(RoaringBitmap().toBitsetWords()?.filter { $0 != 0 }, [])
    }

    func testToBitsetWordRange() {
        let a: RoaringBitmap = [0, 1, 63, 64, 130, 70_000]
        a.addRange(min: 1_000_000, max: 1_000_200)
        guard let all = a.toBitsetWords() else {
            return XCTFail("could not build the bitset")
        }
        XCTAssertEqual(a.toBitsetWords(firstWord: 0, count: 4), Array(all[0..<4]))
        XCTAssertEqual(a.toBitsetWords(firstWord: 1, count: 2), [1, 4])
        XCTAssertEqual(a.toBitsetWords(firstWord: 15_620, count: 8), Array(all[15_620..<15_628]))
        XCTAssertEqual(a.toBitsetWords(firstWord: 1_000, count: 0), [])
        // The words are written whether or not they hold values.
        XCTAssertEqual(a.toBitsetWords(firstWord: 100, count: 3), [0, 0, 0])
        // The last word of the 32-bit range.
        let top: RoaringBitmap = [UInt32.max]
        XCTAssertEqual(top.toBitsetWords(firstWord: 1 << 26 - 1, count: 1), [1 << 63])
    }

    func testDeserializeSafe() {
        let a = RoaringBitmap(range: 0..<100, step: 3)
        var buffer = [Int8](repeating: 0, count: a.sizeInBytes())
        XCTAssertEqual(a.serialize(buffer: &buffer), buffer.count)

        XCTAssertEqual(
            RoaringBitmap.deserializeSafe(buffer: buffer, maxbytes: buffer.count),
            a
        )
        // A buffer too short for the header is rejected instead of over-reading.
        XCTAssertNil(RoaringBitmap.deserializeSafe(buffer: buffer, maxbytes: 1))
    }

    func testFrozenSerialization() {
        let a = RoaringBitmap(range: 0..<1000, step: 3)
        _ = a.runOptimize()
        _ = a.shrink()

        let bytes = a.frozenSerialize()
        XCTAssertEqual(bytes.count, a.frozenSizeInBytes())

        guard let view = RoaringBitmap.frozenView(bytes: bytes) else {
            return XCTFail("frozen view could not be created")
        }
        XCTAssertEqual(view, a)
        XCTAssertEqual(view.toArray(), a.toArray())
    }

    func testPortableDeserializeFrozen() {
        let a = RoaringBitmap(range: 0..<1000, step: 3)
        var buffer = [Int8](repeating: 0, count: a.portableSizeInBytes())
        XCTAssertEqual(a.portableSerialize(buffer: &buffer), buffer.count)

        let bytes = buffer.map { UInt8(bitPattern: $0) }
        guard let view = RoaringBitmap.portableDeserializeFrozen(bytes: bytes) else {
            return XCTFail("frozen bitmap could not be read")
        }
        XCTAssertEqual(view, a)
        XCTAssertEqual(view.toArray(), a.toArray())
    }

    func testEmptyBitmapRoundTrips() {
        let empty = RoaringBitmap()
        _ = empty.shrink()

        guard let frozen = RoaringBitmap.frozenView(bytes: empty.frozenSerialize()) else {
            return XCTFail("frozen view of an empty bitmap could not be created")
        }
        XCTAssertTrue(frozen.isEmpty)

        var buffer = [Int8](repeating: 0, count: empty.portableSizeInBytes())
        _ = empty.portableSerialize(buffer: &buffer)
        let bytes = buffer.map { UInt8(bitPattern: $0) }
        XCTAssertEqual(RoaringBitmap.portableDeserializeFrozen(bytes: bytes)?.isEmpty, true)

        XCTAssertEqual(empty.toArray(offset: 0, limit: 10), [])
        XCTAssertEqual(empty.rankMany([1, 2]), [0, 0])
        XCTAssertNil(empty.select(rank: 0))
        XCTAssertNil(empty.index(of: 0))
        XCTAssertTrue(empty.iterate { _ in true })
    }

    func testInternalValidate() {
        let a = RoaringBitmap(range: 0..<1000, step: 3)
        XCTAssertNil(a.internalValidate())
        _ = a.runOptimize()
        XCTAssertNil(a.internalValidate())
    }
}
