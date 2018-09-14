import XCTest
@testable import SwiftRoaring


extension swiftRoaringTests {
    static var allTests : [(String, (swiftRoaringTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample)
        ]
    }
}

class swiftRoaringTests: XCTestCase {
    var rbm: RoaringBitmap!

    override func setUp() {
        super.setUp()
        rbm = RoaringBitmap()
    }

    func testExample() {
        
        // bitmap.add(x: 35)
        // XCTAssertEqual(bitmap.contains(x: 35), true)
        //XCTAssertEqual(true, true)
    }
}