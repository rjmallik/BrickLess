import XCTest
@testable import PlayMatch

/// OSM sport classification: how a sports tag maps to a sport,
/// and the default name for a venue of each sport.
final class CourtSportTests: XCTestCase {

    func testSportFromTag() {
        XCTAssertEqual(Court.sport(fromSportsTag: "basketball"), "basketball")
        XCTAssertEqual(Court.sport(fromSportsTag: "soccer"), "soccer")
        // A bare "football" tag means soccer in most of the world.
        XCTAssertEqual(Court.sport(fromSportsTag: "football"), "soccer")
        XCTAssertEqual(Court.sport(fromSportsTag: "american_football"), "football")
        XCTAssertEqual(Court.sport(fromSportsTag: "tennis"), "tennis")
        XCTAssertEqual(Court.sport(fromSportsTag: "pickleball"), "pickleball")
        XCTAssertEqual(Court.sport(fromSportsTag: "table_tennis"), "table_tennis")
        XCTAssertEqual(Court.sport(fromSportsTag: "basketball;soccer"), "multi")
        XCTAssertEqual(Court.sport(fromSportsTag: "basketball;american_football"), "multi")
        XCTAssertEqual(Court.sport(fromSportsTag: "soccer;american_football"), "multi")
        XCTAssertEqual(Court.sport(fromSportsTag: "tennis;pickleball"), "multi")
        XCTAssertEqual(Court.sport(fromSportsTag: "volleyball"), "basketball") // unknown defaults to basketball
        XCTAssertEqual(Court.sport(fromSportsTag: ""), "basketball")
    }

    func testDefaultNameForSport() {
        XCTAssertEqual(Court.defaultName(forSport: "basketball"), "Basketball court")
        XCTAssertEqual(Court.defaultName(forSport: "soccer"), "Soccer field")
        XCTAssertEqual(Court.defaultName(forSport: "football"), "Football field")
        XCTAssertEqual(Court.defaultName(forSport: "tennis"), "Tennis court")
        XCTAssertEqual(Court.defaultName(forSport: "pickleball"), "Pickleball court")
        XCTAssertEqual(Court.defaultName(forSport: "table_tennis"), "Table tennis table")
        XCTAssertEqual(Court.defaultName(forSport: "multi"), "Multi-sport pitch")
    }
}
