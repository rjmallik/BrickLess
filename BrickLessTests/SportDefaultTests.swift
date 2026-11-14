import XCTest
@testable import PlayMatch

/// Court tab and create-form default sport: a venue picks its own
/// sport's tab, a multi-sport pitch falls back to the player's
/// primary sport, then to basketball.
final class SportDefaultTests: XCTestCase {

    private func makeCourt(sport: String) -> Court {
        Court(id: "court-\(sport)", name: "Test court", sport: sport,
              latitude: 47.6062, longitude: -122.3321,
              surface: "", lit: false, indoor: false,
              source: "community", createdBy: nil)
    }

    func testFilterForCourt() {
        XCTAssertEqual(SportTabs.filterForCourt(nil), "all")
        XCTAssertEqual(SportTabs.filterForCourt(makeCourt(sport: "soccer")), "soccer")
        XCTAssertEqual(SportTabs.filterForCourt(makeCourt(sport: "football")), "football")
        // A multi-sport pitch hosts games of any sport, so no single tab fits it.
        XCTAssertEqual(SportTabs.filterForCourt(makeCourt(sport: "multi")), "all")
    }

    func testDefaultSportFromCourt() {
        // Every one of the six launch sports, individually. The primary
        // is always a different sport, so the court sport must be what
        // wins.
        for tag in SportTabs.sports.map(\.tag) {
            let primary = tag == "basketball" ? "Soccer" : "Basketball"
            XCTAssertEqual(SportTabs.defaultSport(court: makeCourt(sport: tag),
                                                 primarySportDisplayName: primary), tag,
                           "court sport \(tag) should win over primary \(primary)")
        }
    }

    func testDefaultSportFallsBackToPrimarySport() {
        // A multi-sport pitch has no single sport, so the player's
        // primary sport is used instead.
        XCTAssertEqual(SportTabs.defaultSport(court: makeCourt(sport: "multi"),
                                             primarySportDisplayName: "Soccer"), "soccer")
        XCTAssertEqual(SportTabs.defaultSport(court: nil,
                                             primarySportDisplayName: "American Football"), "football")
    }

    func testDefaultSportFallsBackToBasketball() {
        XCTAssertEqual(SportTabs.defaultSport(court: makeCourt(sport: "multi"),
                                             primarySportDisplayName: nil), "basketball")
        XCTAssertEqual(SportTabs.defaultSport(court: nil, primarySportDisplayName: nil), "basketball")
        XCTAssertEqual(SportTabs.defaultSport(court: nil, primarySportDisplayName: "Golf"), "basketball")
    }
}
