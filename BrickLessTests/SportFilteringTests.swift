import XCTest
@testable import PlayMatch

/// Sport-tab filtering: courts and games match the All tab and
/// their own sport's tab, never another sport's; a multi-sport
/// pitch matches every sport tab.
final class SportFilteringTests: XCTestCase {

    private func makeCourt(sport: String) -> Court {
        Court(id: "court-\(sport)", name: "Test court", sport: sport,
              latitude: 47.6062, longitude: -122.3321,
              surface: "", lit: false, indoor: false,
              source: "community", createdBy: nil)
    }

    func testCourtMatchesAll() {
        XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: "basketball"), filter: "all"))
        XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: "soccer"), filter: "all"))
        XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: "multi"), filter: "all"))
    }

    func testCourtMatchesOwnSport() {
        // Every one of the six launch sports, individually.
        for tag in SportTabs.sports.map(\.tag) {
            XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: tag), filter: tag),
                          "\(tag) court should match the \(tag) tab")
        }
    }

    func testCourtDoesNotMatchOtherSport() {
        // Every sport as the non-matching case at least once: each
        // court's sport is checked against the next sport's tab.
        let tags = SportTabs.sports.map(\.tag)
        for (index, tag) in tags.enumerated() {
            let other = tags[(index + 1) % tags.count]
            XCTAssertFalse(SportTabs.courtMatches(makeCourt(sport: tag), filter: other),
                           "\(tag) court should not match the \(other) tab")
        }
    }

    func testMultiSportCourtMatchesAnySportTab() {
        let multi = makeCourt(sport: "multi")
        for tag in SportTabs.sports.map(\.tag) {
            XCTAssertTrue(SportTabs.courtMatches(multi, filter: tag), "multi should match \(tag)")
        }
    }

    func testEventMatchesAll() {
        XCTAssertTrue(SportTabs.eventMatches(makeEvent(sport: "soccer"), filter: "all"))
    }

    func testEventMatchesOwnSport() {
        // Every one of the six launch sports, individually.
        for tag in SportTabs.sports.map(\.tag) {
            XCTAssertTrue(SportTabs.eventMatches(makeEvent(sport: tag), filter: tag),
                          "\(tag) game should match the \(tag) tab")
        }
    }

    func testEventDoesNotMatchOtherSport() {
        // Every sport as the non-matching case at least once: each
        // game's sport is checked against the next sport's tab.
        let tags = SportTabs.sports.map(\.tag)
        for (index, tag) in tags.enumerated() {
            let other = tags[(index + 1) % tags.count]
            XCTAssertFalse(SportTabs.eventMatches(makeEvent(sport: tag), filter: other),
                           "\(tag) game should not match the \(other) tab")
        }
    }
}
