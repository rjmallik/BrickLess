import XCTest
@testable import PlayMatch

/// Per-sport profiles: positions per sport, the overall highest
/// level (max across sports), and the primary sport profile.
final class PerSportProfileTests: XCTestCase {

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
