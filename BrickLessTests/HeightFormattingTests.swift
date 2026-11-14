import XCTest
@testable import PlayMatch

/// Height display: inches format as feet/inches, and the profile's
/// height ranges cover 3-8 feet.
final class HeightFormattingTests: XCTestCase {

    func testFormattedHeight() {
        XCTAssertEqual(UserProfile.formattedHeight(74), "6'2\"")
        XCTAssertEqual(UserProfile.formattedHeight(72), "6'0\"")
        XCTAssertEqual(UserProfile.formattedHeight(60), "5'0\"")
        XCTAssertEqual(UserProfile.formattedHeight(83), "6'11\"")
        XCTAssertEqual(UserProfile.formattedHeight(36), "3'0\"")
    }

    func testHeightFormattedProperty() {
        XCTAssertEqual(makeProfile(heightInches: 74).heightFormatted, "6'2\"")
        XCTAssertNil(makeProfile().heightFormatted)
    }

    func testHeightFeetRange() {
        XCTAssertTrue(UserProfile.heightFeetRange.contains(3))
        XCTAssertTrue(UserProfile.heightFeetRange.contains(8))
        XCTAssertFalse(UserProfile.heightFeetRange.contains(2))
        XCTAssertFalse(UserProfile.heightFeetRange.contains(9))
    }
}
