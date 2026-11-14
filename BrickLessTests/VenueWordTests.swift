import XCTest
@testable import PlayMatch

/// Venue wording follows the sport: court, field, table, or pitch,
/// singular and plural.
final class VenueWordTests: XCTestCase {

    /// Each sport's venue word, one assertion per sport plus multi:
    /// courts for basketball, tennis and pickleball; fields for soccer
    /// and American football; a table for table tennis; a pitch for a
    /// multi-sport pitch.
    func testVenueWordForEachSport() {
        XCTAssertEqual(Court.venueWord(forSport: "basketball"), "court")
        XCTAssertEqual(Court.venueWord(forSport: "tennis"), "court")
        XCTAssertEqual(Court.venueWord(forSport: "pickleball"), "court")
        XCTAssertEqual(Court.venueWord(forSport: "soccer"), "field")
        XCTAssertEqual(Court.venueWord(forSport: "football"), "field")
        XCTAssertEqual(Court.venueWord(forSport: "table_tennis"), "table")
        XCTAssertEqual(Court.venueWord(forSport: "multi"), "pitch")
        // The OSM tag form of American football can leak in from
        // community courts added before the Add Court picker stored
        // Court.sport tags; it is still a field.
        XCTAssertEqual(Court.venueWord(forSport: "american_football"), "field")
        XCTAssertEqual(Court.venueWord(forSport: "unknown"), "court")
    }

    func testVenueWordPluralForEachSport() {
        XCTAssertEqual(Court.venueWordPlural(forSport: "basketball"), "courts")
        XCTAssertEqual(Court.venueWordPlural(forSport: "tennis"), "courts")
        XCTAssertEqual(Court.venueWordPlural(forSport: "pickleball"), "courts")
        XCTAssertEqual(Court.venueWordPlural(forSport: "soccer"), "fields")
        XCTAssertEqual(Court.venueWordPlural(forSport: "football"), "fields")
        XCTAssertEqual(Court.venueWordPlural(forSport: "table_tennis"), "tables")
        // "pitch" pluralises to "pitches", not "pitchs".
        XCTAssertEqual(Court.venueWordPlural(forSport: "multi"), "pitches")
    }
}
