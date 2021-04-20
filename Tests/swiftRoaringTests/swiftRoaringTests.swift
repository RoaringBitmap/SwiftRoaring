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
            ("testJaccardIndex", testJaccardIndex),
            ("testDescription", testDescription), 
            ("testHashValue", testHashValue),   
            ("testBase64", testBase64),    

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
        rbm.add(35)
        XCTAssertEqual(rbm.contains(35), true)
    }

    func testRemove() {
        rbm.add(35)
        rbm.remove(35)
        XCTAssertEqual(rbm.contains(35), false)
    }

    func testClear() {
        for k in stride(from: 0, to: 10000, by: 100 ) {
            rbm.add(UInt32(k))
        }
        XCTAssertEqual(rbm.isEmpty, false)
        rbm.clear()
        XCTAssertEqual(rbm.isEmpty, true)
    }

    func testIterator() {
        var count = 0
        for k in stride(from: 0, to: 10000, by: 100 ) {
            rbm.add(UInt32(k))
            count += 1
        }
        for i in rbm {
            XCTAssertEqual(rbm.contains(i), true)
            count -= 1
            if(count < 0) {break}
        }
        XCTAssertEqual(count, 0)
    }

    func testInitRange(){
        let rbmRange = RoaringBitmap(min: 0,max: 1000,step: 50)
        for k in stride(from: 0, to: 1000, by: 50 ) {
            XCTAssertEqual(rbmRange.contains(UInt32(k)), true)
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
            XCTAssertEqual(rbmArray.contains(UInt32(i)), true)
        }
        let l: RoaringBitmap = [0,1,2,4,5,6]
        for i in array {
            XCTAssertEqual(l.contains(UInt32(i)), true)
        }
    }

    func testFlip(){
        rbm.addRangeClosed(min:0, max:500)
        let flip = rbm.flip(rangeStart: 0, rangeEnd:501)
        XCTAssertTrue(flip.isEmpty)
        rbm.flipInplace(rangeStart: 0, rangeEnd:501)
        XCTAssertTrue(rbm.isEmpty)
    }

    func testEquals(){
        let cpy = rbm.copy()
        XCTAssertTrue(cpy.equals(rbm))
        XCTAssertTrue(cpy == rbm)
        XCTAssertEqual(cpy != rbm, false)
    }

    func testSubset(){
        let cpy = rbm.copy()
        XCTAssertTrue(rbm.isSubset(of: cpy))
        cpy.add(800)
        XCTAssertTrue(rbm.isStrictSubset(of: cpy))
        cpy.remove(800)
    }

    func testOptimisations(){
        rbm.addRangeClosed(min:0, max:500)
        XCTAssertTrue(rbm.sizeInBytes() > 0)
        XCTAssertTrue(rbm.shrink() >= 0)
        XCTAssertTrue(rbm.runOptimize())
        XCTAssertTrue(rbm.removeRunCompression())
    }

    func testPrinting(){
        let rbmap = RoaringBitmap()
        rbmap.add(1)
        rbmap.describe()
        rbmap.print()
    }

    func testToArray(){
        rbm.add(35)
        var array = rbm.toArray()
        for i in rbm {
            if let index = array.index(of: i) {
                array.remove(at: index)
            }
        }
        XCTAssertTrue(array.count == 0)
        XCTAssertTrue(rbm.count == 1)
    }

    func testAddingRemoving(){
        rbm.addRangeClosed(min:0, max:500)
        let cpy = rbm.copy()
        _ = cpy.containsRange(start:0, end:501)
        XCTAssertEqual(cpy.max(), 500)
        XCTAssertEqual(cpy.min(), 0)
        XCTAssertEqual(cpy.rank(value: 499), 500)
        let rbmap = RoaringBitmap()
        rbmap.addRange(min: 0, max: 11)
        XCTAssertTrue(rbmap.count == 11)
        rbmap.removeRange(min: 0, max: 11)
        XCTAssertTrue(rbmap.count == 0)
        rbmap.addRange(min: 0, max: 11)
        rbmap.removeRangeClosed(min: 0, max: 10)
        XCTAssertTrue(rbmap.count == 0)
        XCTAssertTrue(rbmap.addCheck(0))
        rbmap.addMany(values: [1,2,3])
        XCTAssertTrue(rbmap.count == 4)
        XCTAssertTrue(rbmap.removeCheck(3))
        XCTAssertTrue(rbmap.count == 3)
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

        let andCardinality = rbm1.intersectionCount(rbm2)
        XCTAssertEqual(Int(andCardinality), andSwift.count)

        XCTAssertEqual(rbm1.intersect(rbm2), andSwift.count > 0)   
    }

    func testOr(){
        let (rbm1, rbm2, swiftSet1, swiftSet2) = makeSets()

        let andRbm = rbm1 | rbm2
        let andSwift = swiftSet1.union(swiftSet2)
        XCTAssertEqual(andSwift, Set(andRbm.toArray()))

        let orCardinality = rbm1.unionCount(rbm2)
        XCTAssertEqual(Int(orCardinality), andSwift.count)

        let (rbm3, rbm4, swiftSet3, swiftSet4) = makeSets()
        var orMany = rbm1.unionMany([rbm2,rbm3,rbm4])
        var swiftOrMany = swiftSet1.union(swiftSet2)
        swiftOrMany = swiftOrMany.union(swiftSet3)
        swiftOrMany = swiftOrMany.union(swiftSet4)
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        orMany = rbm1.unionManyHeap([rbm2,rbm3,rbm4])
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        let lazy = rbm3.lazyUnion(rbm4, bitsetconversion: false)
        XCTAssertEqual(swiftSet3.union(swiftSet4), Set(lazy.toArray()))
        rbm3.formLazyUnion(rbm4, bitsetconversion: false)
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

        let xorCardinality = rbm1.symmetricDifferenceCount(rbm2)
        XCTAssertEqual(Int(xorCardinality), andSwift.count)

        let (rbm3, rbm4, swiftSet3, swiftSet4) = makeSets()
        let orMany = rbm1.symmetricDifferenceMany([rbm2,rbm3,rbm4])
        var swiftOrMany = swiftSet1.symmetricDifference(swiftSet2)
        swiftOrMany = swiftOrMany.symmetricDifference(swiftSet3)
        swiftOrMany = swiftOrMany.symmetricDifference(swiftSet4)
        XCTAssertEqual(swiftOrMany, Set(orMany.toArray()))

        let lazy = rbm3.lazySymmetricDifference(rbm4)
        XCTAssertEqual(swiftSet3.symmetricDifference(swiftSet4), Set(lazy.toArray()))
        rbm3.formLazySymmetricDifference(rbm4)
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

        let andNotCardinality = rbm1.subtractingCount(rbm2)
        XCTAssertEqual(Int(andNotCardinality), andSwift.count)
    }

    func testSerialize(){
        rbm.addRangeClosed(min:0, max:500)
        let size = rbm.sizeInBytes()
        var buffer = [Int8](repeating: 0, count: size)
        XCTAssertEqual(rbm.serialize(buffer: &buffer), size)
        let deserializedRbm = RoaringBitmap.deserialize(buffer: buffer)
        XCTAssertTrue(deserializedRbm == rbm)

    }

    func testPortableSerialize(){
        rbm.addRangeClosed(min:0, max:500)
        let size = rbm.portableSizeInBytes()
        var buffer = [Int8](repeating: 0, count: size)
        XCTAssertEqual(rbm.portableSerialize(buffer: &buffer), size)
        let deserializedRbm = RoaringBitmap.portableDeserialize(buffer: buffer)
        XCTAssertTrue(deserializedRbm == rbm)
        let safeSize = RoaringBitmap.portableDeserializeSize(buffer: buffer, maxbytes: size)
        let deserializedSafeRbm = RoaringBitmap.portableDeserializeSafe(buffer: buffer, maxbytes: safeSize)
        XCTAssertTrue(deserializedSafeRbm == rbm)
    }

    func testBase64(){
        let bitmap = RoaringBitmap()
        for i in 0..<50 { 
          // from https://github.com/RoaringBitmap/SwiftRoaring/issues/1
          let random = Int.random(in: 0...1)
          if random == 0 {
            bitmap.add(UInt32(i))
          }
        } 
        let size = rbm.portableSizeInBytes()
        var buffer = [Int8](repeating: 0, count: size)
        XCTAssertEqual(rbm.portableSerialize(buffer: &buffer), size)
        let uint8Buffer = buffer.map { UInt8(bitPattern: $0) }
        let base64Encoded = Data(uint8Buffer).base64EncodedString()
        let decoded = Data(base64Encoded: base64Encoded)!
        XCTAssertEqual(decoded.count, size)
        _ = buffer.withUnsafeMutableBytes { decoded.copyBytes(to: $0) }
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

    func testJaccardIndex(){
        rbm.addMany(values: [1,2,3])
        let rbm2 = RoaringBitmap(values: [3,4,5])
        XCTAssertEqual(rbm.jaccardIndex(rbm2), 0.2)
    }

    func testDescription(){
        rbm.addRangeClosed(min:0, max:500)
        print(rbm.description)
    }

    func testHashValue(){
        print(rbm.hashValue)
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