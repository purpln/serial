import XCTest
@testable import serial

final class serialTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(serial().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
