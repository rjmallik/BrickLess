import XCTest
@testable import PlayMatch

/// Signup + profile rules: what a new user can and cannot enter.
final class UserProfileTests: XCTestCase {

    // MARK: - Usernames (3-20 chars, letters, numbers, underscores)

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

    // MARK: - Email

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

    // MARK: - Denylist (Guideline 1.2)

    func testBlockedWordsCaught() {
        XCTAssertTrue(UserProfile.containsBlockedWord("shithead"))
        XCTAssertTrue(UserProfile.containsBlockedWord("SHIT"))
        XCTAssertTrue(UserProfile.containsBlockedWord("Dickinson")) // substring match
        XCTAssertTrue(UserProfile.containsBlockedWord("my fuck team"))
    }

    func testCleanNamesPassDenylist() {
        XCTAssertFalse(UserProfile.containsBlockedWord("rjmallik"))
        XCTAssertFalse(UserProfile.containsBlockedWord("Ballers"))
        XCTAssertFalse(UserProfile.containsBlockedWord("classy"))
    }

    // MARK: - Height

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

    // MARK: - Age and level

    func testAgeRangeBounds() {
        XCTAssertTrue(UserProfile.ageRange.contains(13))
        XCTAssertTrue(UserProfile.ageRange.contains(100))
        XCTAssertFalse(UserProfile.ageRange.contains(12))
        XCTAssertFalse(UserProfile.ageRange.contains(101))
    }

    func testHighestLevels() {
        XCTAssertEqual(UserProfile.highestLevels.first, "Recreational")
        XCTAssertEqual(UserProfile.highestLevels.last, "Professional")
        XCTAssertEqual(UserProfile.highestLevels.count, 6)
        XCTAssertEqual(UserProfile.defaultHighestLevel, "Recreational")
    }

    func testHeightFeetRange() {
        XCTAssertTrue(UserProfile.heightFeetRange.contains(3))
        XCTAssertTrue(UserProfile.heightFeetRange.contains(8))
        XCTAssertFalse(UserProfile.heightFeetRange.contains(2))
        XCTAssertFalse(UserProfile.heightFeetRange.contains(9))
    }

    // MARK: - Age parsing (profile setup field)

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

    // MARK: - Per-sport positions

    func testPositionsForSport() {
        XCTAssertEqual(UserProfile.positions(forSport: "Basketball"),
                       ["Any", "Point Guard", "Shooting Guard", "Small Forward", "Power Forward", "Center"])
        XCTAssertEqual(UserProfile.positions(forSport: "Soccer"),
                       ["Any", "Goalkeeper", "Defender", "Midfielder", "Forward"])
        XCTAssertTrue(UserProfile.positions(forSport: "American Football").contains("Quarterback"))
        XCTAssertTrue(UserProfile.positions(forSport: "American Football").contains("Wide Receiver"))
        // Racket sports have no field positions: the choice is the format.
        XCTAssertEqual(UserProfile.positions(forSport: "Tennis"), ["Any", "Singles", "Doubles"])
        XCTAssertEqual(UserProfile.positions(forSport: "Pickleball"), ["Any", "Singles", "Doubles"])
        XCTAssertEqual(UserProfile.positions(forSport: "Table Tennis"), ["Any", "Singles", "Doubles"])
        // Unknown sport falls back to basketball.
        XCTAssertEqual(UserProfile.positions(forSport: "Golf"), UserProfile.positions)
    }

    // MARK: - Overall highest level (max across sports)

    func testOverallHighestLevelTakesMax() {
        let profiles = [
            SportProfile(sport: "Basketball", positions: ["Point Guard"],
                         skillLevel: "Advanced", highestLevel: "College"),
            SportProfile(sport: "Tennis", positions: ["Singles"],
                         skillLevel: "Intermediate", highestLevel: "Professional"),
        ]
        XCTAssertEqual(UserProfile.overallHighestLevel(from: profiles), "Professional")
    }

    func testOverallHighestLevelNilWhenNothingSpecified() {
        let profiles = [
            SportProfile(sport: "Basketball", positions: ["Any"],
                         skillLevel: "Beginner", highestLevel: nil),
            SportProfile(sport: "Soccer", positions: ["Any"],
                         skillLevel: "Beginner", highestLevel: nil),
        ]
        XCTAssertNil(UserProfile.overallHighestLevel(from: profiles))
        XCTAssertNil(UserProfile.overallHighestLevel(from: []))
    }

    func testOverallHighestLevelIgnoresUnspecifiedSports() {
        let profiles = [
            SportProfile(sport: "Basketball", positions: ["Any"],
                         skillLevel: "Beginner", highestLevel: nil),
            SportProfile(sport: "Soccer", positions: ["Forward"],
                         skillLevel: "Intermediate", highestLevel: "High School"),
        ]
        XCTAssertEqual(UserProfile.overallHighestLevel(from: profiles), "High School")
    }

    // MARK: - Primary sport profile

    func testPrimarySportProfileIsFirstInAllSportsOrder() {
        let profiles = [
            SportProfile(sport: "Tennis", positions: ["Singles"],
                         skillLevel: "Advanced", highestLevel: nil),
            SportProfile(sport: "Basketball", positions: ["Point Guard"],
                         skillLevel: "Intermediate", highestLevel: nil),
        ]
        // Basketball comes first in allSports, even though Tennis was listed first.
        XCTAssertEqual(UserProfile.primarySportProfile(from: profiles)?.sport, "Basketball")
        XCTAssertNil(UserProfile.primarySportProfile(from: []))
    }
}
