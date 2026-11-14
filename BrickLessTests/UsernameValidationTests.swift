import XCTest
@testable import PlayMatch

/// Username rules: 3-20 chars, letters, numbers, underscores only.
final class UsernameValidationTests: XCTestCase {

    func testValidUsernamesPass() {
        XCTAssertTrue(UserProfile.isValidUsername("rjmallik"))
        XCTAssertTrue(UserProfile.isValidUsername("RJHoops"))
        XCTAssertTrue(UserProfile.isValidUsername("rj_hoops99"))
        XCTAssertTrue(UserProfile.isValidUsername("abc")) // minimum length
        XCTAssertTrue(UserProfile.isValidUsername("abcdefghijklmnopqrst")) // 20 chars
    }

    func testUsernameTooShortOrTooLongFails() {
        XCTAssertFalse(UserProfile.isValidUsername("rj"))
        XCTAssertFalse(UserProfile.isValidUsername(""))
        XCTAssertFalse(UserProfile.isValidUsername("abcdefghijklmnopqrstu")) // 21 chars
    }

    func testUsernameDisallowedCharactersFail() {
        XCTAssertFalse(UserProfile.isValidUsername("rj hoops"))
        XCTAssertFalse(UserProfile.isValidUsername("rj-hoops"))
        XCTAssertFalse(UserProfile.isValidUsername("rj.hoops"))
        XCTAssertFalse(UserProfile.isValidUsername("rj@hoops"))
    }
}
