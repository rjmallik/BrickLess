import XCTest
import CoreLocation
@testable import BrickLess

/// Court map: grid cells for the geo-scoped fetch, OSM sport
/// classification, and the all-phases-except-golf launch scope.
final class CourtTests: XCTestCase {

    // MARK: - Grid keys (~1 km cells)

    func testGridKeyForSeattle() {
        // Downtown Seattle, matching the doc comment on Court.gridKey.
        XCTAssertEqual(Court.gridKey(latitude: 47.6062, longitude: -122.3321), "4760_-12233")
    }

    func testGridKeyAtOriginAndSouthernHemisphere() {
        XCTAssertEqual(Court.gridKey(latitude: 0, longitude: 0), "0_0")
        XCTAssertEqual(Court.gridKey(latitude: -33.8688, longitude: 151.2093), "-3386_15120")
    }

    func testNearbyGridKeysCoverCenterAndNeighbours() {
        let keys = Court.nearbyGridKeys(around: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321))
        XCTAssertEqual(keys.count, 9)
        XCTAssertEqual(Set(keys).count, 9) // all distinct
        XCTAssertTrue(keys.contains("4760_-12233")) // the center cell
        XCTAssertTrue(keys.contains("4761_-12232"))
        XCTAssertTrue(keys.contains("4759_-12234"))
    }

    // MARK: - OSM sport classification

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

    // MARK: - Launch scope

    /// All phases except golf (phase 4): basketball, soccer + American
    /// football, tennis + pickleball + table tennis. The map list is in
    /// OSM tag form, the signup list in display-name form.
    func testLaunchSportsAllPhasesExceptGolf() {
        XCTAssertEqual(CourtStore.launchSports,
                       ["basketball", "soccer", "american_football",
                        "tennis", "pickleball", "table_tennis"])
        XCTAssertEqual(UserProfile.allSports,
                       ["Basketball", "Soccer", "American Football",
                        "Tennis", "Pickleball", "Table Tennis"])
        XCTAssertFalse(CourtStore.launchSports.contains("golf"))
        XCTAssertFalse(UserProfile.allSports.contains("Golf"))
    }
}
