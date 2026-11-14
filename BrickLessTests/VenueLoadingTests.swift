import XCTest
@testable import PlayMatch

/// Venue loading indicator: the Finding/Loading text alternates
/// and the sport tag cycles through all seven sports, then repeats.
final class VenueLoadingTests: XCTestCase {

    func testLoadingCycleTextAlternatesFindingAndLoading() {
        XCTAssertEqual(VenueLoadingCycle.text(at: 0), "Finding…")
        XCTAssertEqual(VenueLoadingCycle.text(at: 1), "Loading…")
        XCTAssertEqual(VenueLoadingCycle.text(at: 2), "Finding…")
        XCTAssertEqual(VenueLoadingCycle.text(at: 3), "Loading…")
    }

    func testLoadingCycleTagsCoverAllSevenSportsThenRepeat() {
        let tags = (0..<7).map { VenueLoadingCycle.tag(at: $0) }
        XCTAssertEqual(tags, ["basketball", "soccer", "football", "tennis",
                              "pickleball", "table_tennis", "golf"])
        // The cycle wraps: step 7 is basketball again.
        XCTAssertEqual(VenueLoadingCycle.tag(at: 7), "basketball")
        XCTAssertEqual(VenueLoadingCycle.tag(at: 8), "soccer")
    }
}
