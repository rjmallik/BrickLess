import XCTest
@testable import PlayMatch

/// Email validation for signup.
final class EmailValidationTests: XCTestCase {

    func testValidEmailsPass() {
        XCTAssertTrue(UserProfile.isValidEmail("rj@example.com"))
        XCTAssertTrue(UserProfile.isValidEmail("a@b.c"))
        XCTAssertTrue(UserProfile.isValidEmail(" rutujit97872@gmail.com ")) // trims whitespace
    }

    func testInvalidEmailsFail() {
        XCTAssertFalse(UserProfile.isValidEmail("rjexample.com"))
        XCTAssertFalse(UserProfile.isValidEmail("rj@example"))
        XCTAssertFalse(UserProfile.isValidEmail("@example.com"))
        XCTAssertFalse(UserProfile.isValidEmail("rj@"))
        XCTAssertFalse(UserProfile.isValidEmail(""))
    }
}
