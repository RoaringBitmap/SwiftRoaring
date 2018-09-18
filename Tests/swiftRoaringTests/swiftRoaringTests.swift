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
            ("testCase1", testCase1),
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
        //TODO
    }

    func testInitArray(){
        var array = [0,1,2,4,5,6]
        let rbmArray = RoaringBitmap(values: array.map{ UInt32($0) })
        for i in array {
            XCTAssertEqual(rbmArray.contains(value: UInt32(i)), true)
        }
    }

    func testCase1(){
        rbm.addRangeClosed(min:0, max:500)
        var cpy = rbm.copy()
        cpy.containsRange(start:0, end:501)
        XCTAssertEqual(cpy.maximum(), 500)
        XCTAssertEqual(cpy.minimum(), 0)
        XCTAssertEqual(cpy.rank(value: 499), 500)
        var element = UInt32(800)
        //TODO: FIX SELECT
        // XCTAssertEqual(cpy.select(rank:500, element: &element), true)
        // XCTAssertEqual(cpy.maximum(), 800)
        let flip = cpy.flip(rangeStart: 0, rangeEnd:501)
        XCTAssertEqual(flip.isEmpty(), true)
        cpy.flipInplace(rangeStart: 0, rangeEnd:501)
        XCTAssertEqual(cpy.isEmpty(), true)
        cpy = rbm.copy()
        XCTAssertEqual(cpy.equals(rbm), true)
        XCTAssertEqual(cpy == rbm, true)
        XCTAssertEqual(cpy != rbm, false)
    }
}