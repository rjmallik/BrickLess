import XCTest
@testable import PlayMatch

/// Venue search scope: OSM venues load within 25 km of the map centre,
/// and the Overpass query caps at 200 results.
final class VenueSearchRadiusTests: XCTestCase {

    func testVenueSearchRadiusIs25Kilometres() {
        XCTAssertEqual(CourtStore.venueSearchRadiusMeters, 25_000)
    }

    func testOverpassResultLimitIs200() {
        XCTAssertEqual(CourtStore.overpassResultLimit, 200)
    }
}
