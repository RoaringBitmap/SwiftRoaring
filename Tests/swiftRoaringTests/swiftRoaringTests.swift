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
            ("testFree", testFree),
            ("testToArray", testToArray),
            ("testPrinting", testPrinting),
            ("testOptimisations", testOptimisations),
            ("testSubset", testSubset),
            ("testEquals", testEquals),
            ("testFlip", testFlip),
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
        var rbmap = RoaringBitmap()
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

    func testFree(){
        rbm.free()
        XCTAssertTrue(rbm.count() == 0)
    }

    func testAddingRemoving(){
        rbm.addRangeClosed(min:0, max:500)
        var cpy = rbm.copy()
        _ = cpy.containsRange(start:0, end:501)
        XCTAssertEqual(cpy.maximum(), 500)
        XCTAssertEqual(cpy.minimum(), 0)
        XCTAssertEqual(cpy.rank(value: 499), 500)
        var rbmap = RoaringBitmap()
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
    }

    func testSelect(){
        var cpy = rbm.copy()
        //var element = UInt32(800)
        //TODO: FIX SELECT
        // XCTAssertEqual(cpy.select(rank:500, element: &element), true)
        // XCTAssertEqual(cpy.maximum(), 800)
    }

    func testOperators(){

    }
}