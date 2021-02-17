import XCTest

import serialTests

var tests = [XCTestCaseEntry]()
tests += serialTests.allTests()
XCTMain(tests)
