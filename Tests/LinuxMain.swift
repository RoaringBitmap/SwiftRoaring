import XCTest

import swiftRoaringTests

var tests = [XCTestCaseEntry]()
tests += swiftRoaringTests.allTests()
XCTMain(tests)