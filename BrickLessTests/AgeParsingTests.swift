import XCTest
@testable import PlayMatch

/// Age parsing for the profile setup field, and the 13-100 age range.
final class AgeParsingTests: XCTestCase {

    func testAgeRangeBounds() {
        XCTAssertTrue(UserProfile.ageRange.contains(13))
        XCTAssertTrue(UserProfile.ageRange.contains(100))
        XCTAssertFalse(UserProfile.ageRange.contains(12))
        XCTAssertFalse(UserProfile.ageRange.contains(101))
    }

    func testParseAgeBlank() {
        XCTAssertEqual(UserProfile.parseAge(""), .blank)
        XCTAssertEqual(UserProfile.parseAge("   "), .blank)
    }

    func testParseAgeValid() {
        XCTAssertEqual(UserProfile.parseAge("13"), .valid(13))
        XCTAssertEqual(UserProfile.parseAge("25"), .valid(25))
        XCTAssertEqual(UserProfile.parseAge("100"), .valid(100))
    }

    func testParseAgeInvalid() {
        XCTAssertEqual(UserProfile.parseAge("12"), .invalid)
        XCTAssertEqual(UserProfile.parseAge("101"), .invalid)
        XCTAssertEqual(UserProfile.parseAge("abc"), .invalid)
        XCTAssertEqual(UserProfile.parseAge("25.5"), .invalid)
        // Plain Int(text) does not trim whitespace, so " 25" is invalid.
        XCTAssertEqual(UserProfile.parseAge(" 25"), .invalid)
    }
}
