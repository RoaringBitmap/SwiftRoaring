import XCTest
@testable import SwiftRoaring


extension swiftRoaringTests {
    static var allTests : [(String, (swiftRoaringTests) -> () throws -> Void)] {
        return [
            ("testAdd", testAdd),
            ("testRemove", testRemove),
            ("testClear", testClear),
            ("testIterator", testIterator),
            ("testInitRange", testInitRange),
            ("testInitArray", testInitArray),
            ("testInitCapacity", testInitCapacity),
            ("testSelect", testSelect),
            ("testAddingRemoving", testAddingRemoving),
            ("testToArray", testToArray),
            ("testPrinting", testPrinting),
            ("testOptimisations", testOptimisations),
            ("testSubset", testSubset),
            ("testEquals", testEquals),
            ("testFlip", testFlip),
            ("testAnd", testAnd),
            ("testOr", testOr),
            ("testXor", testXor),
            ("testAndNot", testAndNot),
            ("testSerialize", testSerialize),
            ("testPortableSerialize", testPortableSerialize),
            ("testStatistics", testStatistics),   
        ]
    }
}

class swiftRoaringTests: XCTestCase {
    var rbm: RoaringBitmap!

    override func setUp() {
        super.setUp()
        rbm = RoaringBitmap()
    }

    func testAdd() {
        rbm.add(value: 35)
        XCTAssertEqual(rbm.contains(value: 35), true)
    }

    func testRemove() {
        rbm.add(value: 35)
        rbm.remove(value: 35)
        XCTAssertEqual(rbm.contains(value: 35), false)
    }

    func testClear() {
        for k in stride(from: 0, to: 10000, by: 100 ) {
            rbm.add(value: UInt32(k))
        }
        XCTAssertEqual(rbm.isEmpty(), false)
        rbm.clear()
        XCTAssertEqual(rbm.isEmpty(), true)
    }

    func testIterator() {
        var count = 0
        for k in stride(from: 0, to: 10000, by: 100 ) {
            rbm.add(value: UInt32(k))
            count += 1
        }
        for i in rbm {
            XCTAssertEqual(rbm.contains(value: i), true)
            count -= 1
            if(count < 0) {break}
        }
        XCTAssertEqual(count, 0)
    }

    func testInitRange(){
        let rbmRange = RoaringBitmap(min: 0,max: 1000,step: 50)
        for k in stride(from: 0, to: 1000, by: 50 ) {
            XCTAssertEqual(rbmRange.contains(value: UInt32(k)), true)
        }
    }

    func testInitCapacity(){
        let rbmCapacity = RoaringBitmap(capacity: 8)
        XCTAssertEqual(rbmCapacity.sizeInBytes(), 5)
    }

    func testInitArray(){
        let array = [0,1,2,4,5,6]
        let rbmArray = RoaringBitmap(values: array.map{ UInt32($0) })
        for i in array {
            XCTAssertEqual(rbmArray.contains(value: UInt32(i)), true)
        }
    }

    func testFlip(){
        rbm.addRangeClosed(min:0, max:500)
        let flip = rbm.flip(rangeStart: 0, rangeEnd:501)
        XCTAssertTrue(flip.isEmpty())
        rbm.flipInplace(rangeStart: 0, rangeEnd:501)
        XCTAssertTrue(rbm.isEmpty())
    }

    func testEquals(){
        let cpy = rbm.copy()
        XCTAssertTrue(cpy.equals(rbm))
        XCTAssertTrue(cpy == rbm)
        XCTAssertEqual(cpy != rbm, false)
    }

    func testSubset(){
        let cpy = rbm.copy()
        XCTAssertTrue(rbm.isSubset(cpy))
        cpy.add(value: 800)
        XCTAssertTrue(rbm.isStrictSubset(cpy))
        cpy.remove(value: 800)
    }

    func testOptimisations(){
        rbm.addRangeClosed(min:0, max:500)
        XCTAssertTrue(rbm.sizeInBytes() > 0)
        XCTAssertTrue(rbm.shrinkToFit() >= 0)
        XCTAssertTrue(rbm.runOptimize())
        XCTAssertTrue(rbm.removeRunCompression())
    }

    func testPrinting(){
        let rbmap = RoaringBitmap()
        rbmap.add(value: 1)
        rbmap.describe()
        rbmap.print()
    }

    func testToArray(){
        rbm.add(value: 35)
        var array = rbm.toArray()
        for i in rbm {
            if let index = array.index(of: i) {
                array.remove(at: index)
            }
        }
        XCTAssertTrue(array.count == 0)
        XCTAssertTrue(rbm.count() == 1)
    }

    func testAddingRemoving(){
        rbm.addRangeClosed(min:0, max:500)
        let cpy = rbm.copy()
        _ = cpy.containsRange(start:0, end:501)
        XCTAssertEqual(cpy.maximum(), 500)
        XCTAssertEqual(cpy.minimum(), 0)
        XCTAssertEqual(cpy.rank(value: 499), 500)
        let rbmap = RoaringBitmap()
        rbmap.addRange(min: 0, max: 11)
        XCTAssertTrue(rbmap.count() == 11)
        rbmap.removeRange(min: 0, max: 11)
        XCTAssertTrue(rbmap.count() == 0)
        rbmap.addRange(min: 0, max: 11)
        rbmap.removeRangeClosed(min: 0, max: 10)
        XCTAssertTrue(rbmap.count() == 0)
        XCTAssertTrue(rbmap.addCheck(value: 0))
        rbmap.addMany(values: [1,2,3])
        XCTAssertTrue(rbmap.count() == 4)
        XCTAssertTrue(rbmap.removeCheck(value: 3))
        XCTAssertTrue(rbmap.count() == 3)
    }

    func testSelect(){
        rbm.addRangeClosed(min:0, max:500)
        XCTAssertTrue(rbm.select(rank:5, value: 800))
        XCTAssertEqual(rbm.rank(value:800), 501)
    }

    func testAnd(){
        let (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 & rbm2
        let andSwift = swiftSet1.intersection(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        rbm1 &= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))

        let andCardinality = rbm1.andCardinality(rbm2)
        XCTAssertEqual(Int(andCardinality), andSwift.count)

        XCTAssertEqual(rbm1.intersect(rbm2), andSwift.count > 0)   
    }

    func testOr(){
        let (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 | rbm2
        let andSwift = swiftSet1.union(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        let orCardinality = rbm1.orCardinality(rbm2)
        XCTAssertEqual(Int(orCardinality), andSwift.count)

        let (rbm3, rbm4, swiftSet3, swiftSet4) = makeSets()
        var orMany = rbm1.orMany([rbm2,rbm3,rbm4])
        var swiftOrMany = swiftSet1.union(swiftSet2)
        swiftOrMany = swiftOrMany.union(swiftSet3)
        swiftOrMany = swiftOrMany.union(swiftSet4)
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        orMany = rbm1.orManyHeap([rbm2,rbm3,rbm4])
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        let lazy = rbm3.lazyOr(rbm4, bitsetconversion: false)
        XCTAssertEqual(swiftSet3.union(swiftSet4), Set(lazy.toArray()))
        rbm3.lazyOrInplace(rbm4, bitsetconversion: false)
        rbm3.repairAfterLazy()
        XCTAssertEqual(swiftSet3.union(swiftSet4), Set(rbm3.toArray()))

        rbm1 |= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))
    }

    func testXor(){
        let (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 ^ rbm2
        let andSwift = swiftSet1.symmetricDifference(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        let xorCardinality = rbm1.xorCardinality(rbm2)
        XCTAssertEqual(Int(xorCardinality), andSwift.count)

        let (rbm3, rbm4, swiftSet3, swiftSet4) = makeSets()
        let orMany = rbm1.xorMany([rbm2,rbm3,rbm4])
        var swiftOrMany = swiftSet1.symmetricDifference(swiftSet2)
        swiftOrMany = swiftOrMany.symmetricDifference(swiftSet3)
        swiftOrMany = swiftOrMany.symmetricDifference(swiftSet4)
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        let lazy = rbm3.lazyXor(rbm4)
        XCTAssertEqual(swiftSet3.symmetricDifference(swiftSet4), Set(lazy.toArray()))
        rbm3.lazyXorInplace(rbm4)
        rbm3.repairAfterLazy()
        XCTAssertEqual(swiftSet3.symmetricDifference(swiftSet4), Set(rbm3.toArray()))

        rbm1 ^= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))
    }

    func testAndNot(){
        let (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 - rbm2
        let andSwift = swiftSet1.subtracting(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        rbm1 -= rbm2
        XCTAssertEqual(andSwift, Set(rbm1.toArray()))

        let andNotCardinality = rbm1.andNotCardinality(rbm2)
        XCTAssertEqual(Int(andNotCardinality), andSwift.count)
    }

    func testSerialize(){
        rbm.addRangeClosed(min:0, max:500)
        let size = rbm.sizeInBytes()
        let buffer = [Int8](repeating: 0, count: size)
        XCTAssertEqual(rbm.serialize(buffer: buffer), size)
        let deserializedRbm = RoaringBitmap.deserialize(buffer: buffer)
        XCTAssertTrue(deserializedRbm == rbm)

    }

    func testPortableSerialize(){
        rbm.addRangeClosed(min:0, max:500)
        let size = rbm.portableSizeInBytes()
        let buffer = [Int8](repeating: 0, count: size)
        XCTAssertEqual(rbm.portableSerialize(buffer: buffer), size)
        let deserializedRbm = RoaringBitmap.portableDeserialize(buffer: buffer)
        XCTAssertTrue(deserializedRbm == rbm)
        let safeSize = RoaringBitmap.portableDeserializeSize(buffer: buffer, maxbytes: size)
        let deserializedSafeRbm = RoaringBitmap.portableDeserializeSafe(buffer: buffer, maxbytes: safeSize)
        XCTAssertTrue(deserializedSafeRbm == rbm)

    }

    func testStatistics(){
        rbm.addRangeClosed(min:0, max:500)
        let stats = rbm.statistics()
        XCTAssertTrue(stats.max_value == 500)
        XCTAssertTrue(stats.min_value == 0)
        XCTAssertTrue(stats.cardinality == 501)
    }

    func makeSets() -> (RoaringBitmap, RoaringBitmap, Set<UInt32>, Set<UInt32>){
        let randList1 = makeList(100)
        let randList2 = makeList(100)
        let rbm1 = RoaringBitmap(values: randList1)
        let rbm2 = RoaringBitmap(values: randList2)
        let swiftSet1 = Set(randList1)
        let swiftSet2 = Set(randList2)

        return (rbm1, rbm2, swiftSet1, swiftSet2)
    }

    func makeList(_ n: Int) -> [UInt32] {
         #if os(Linux)
            return (0..<n).map{ _ in UInt32(Int.random(in: 0 ..< 1000)) }
        #else
            return (0..<n).map{ _ in UInt32(arc4random_uniform(1000)+1) }
        #endif
    }
}