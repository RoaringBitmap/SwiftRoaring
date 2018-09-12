import XCTest
@testable import test

final class testTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(test().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
