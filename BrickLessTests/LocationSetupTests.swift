import XCTest
import CoreLocation
@testable import PlayMatch

/// Profile-setup location step: what the setup screen shows for each
/// authorization state. Pure mapping, no device needed. The key
/// guarantees: the prompt is offered only when iOS has never asked
/// (notDetermined), and signup never depends on location — denied or
/// restricted just shows the fallback note.
final class LocationSetupTests: XCTestCase {

    func testNotDeterminedOffersToEnable() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .notDetermined), .offerToEnable)
    }

    func testAuthorizedWhenInUseIsEnabled() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .authorizedWhenInUse), .enabled)
    }

    func testAuthorizedAlwaysIsEnabled() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .authorizedAlways), .enabled)
    }

    func testDeniedIsUnavailable() {
        // iOS will not re-prompt once denied, so there is no button:
        // the user finishes signup and the map's fallback covers it.
        XCTAssertEqual(LocationManager.setupPrompt(for: .denied), .unavailable)
    }

    func testRestrictedIsUnavailable() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .restricted), .unavailable)
    }

    // MARK: - City autofill (LocationSuggestions)

    func testDisplayTextBareTitleWhenNoSubtitle() {
        XCTAssertEqual(LocationSuggestions.displayText(title: "Seattle", subtitle: ""),
                       "Seattle")
    }

    func testDisplayTextKeepsStateFromSubtitle() {
        // "California, United States" -> just the state part.
        XCTAssertEqual(LocationSuggestions.displayText(title: "San Francisco",
                                                       subtitle: "California, United States"),
                       "San Francisco, California")
        XCTAssertEqual(LocationSuggestions.displayText(title: "Austin",
                                                       subtitle: "TX, United States"),
                       "Austin, TX")
    }

    func testMatchingCitiesIsPrefixFirstAndCaseInsensitive() {
        let matches = LocationSuggestions.matchingCities(query: "san")
        XCTAssertTrue(matches.contains("San Francisco, CA"))
        XCTAssertTrue(matches.contains("San Diego, CA"))
        XCTAssertTrue(matches.contains("San Jose, CA"))
        XCTAssertTrue(matches.contains("San Antonio, TX"))
        // All of them start with the query, so they rank as prefix matches.
        XCTAssertTrue(matches.allSatisfy { $0.lowercased().hasPrefix("san") })
    }

    func testMatchingCitiesCapsAtFive() {
        // "s" matches far more than five cities; only five come back.
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "s").count, 5)
    }

    func testMatchingCitiesFindsSubstringMatches() {
        // "york" is not a prefix of any city name, but New York contains it.
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "york"), ["New York, NY"])
    }

    func testMatchingCitiesBlankQueryMatchesNothing() {
        XCTAssertEqual(LocationSuggestions.matchingCities(query: ""), [])
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "   "), [])
    }

    func testMatchingCitiesNoMatchIsEmpty() {
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "zzz"), [])
    }

    // MARK: - Venue loading cycle (VenueLoadingCycle)

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

    // MARK: - Profile city drives the map (CityGeocoder)

    func testNormalizedCityTrimsAndLowercases() {
        XCTAssertEqual(CityGeocoder.normalizedCity("  Seattle, WA "), "seattle, wa")
        XCTAssertEqual(CityGeocoder.normalizedCity("SAN FRANCISCO, CA"), "san francisco, ca")
        XCTAssertEqual(CityGeocoder.normalizedCity(""), "")
    }

    func testCenterChoicePrefersProfileCityOverGPS() {
        // A set profile city wins even when a GPS fix exists: that is
        // the point — the map follows the city the player chose.
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: "Seattle, WA", hasGPSFix: true),
                       .profileCity)
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: "Seattle, WA", hasGPSFix: false),
                       .profileCity)
    }

    func testCenterChoiceFallsBackToGPSThenSeattle() {
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: nil, hasGPSFix: true), .gps)
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: "", hasGPSFix: true), .gps)
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: "   ", hasGPSFix: true), .gps)
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: nil, hasGPSFix: false), .seattle)
        XCTAssertEqual(CityGeocoder.centerChoice(profileCity: "", hasGPSFix: false), .seattle)
    }

    func testDistanceMetersSanFranciscoToCupertinoIsFar() {
        // San Francisco to Cupertino (Apple HQ, the simulator's fake
        // fix) is roughly 50 km — well past the 25 km away threshold.
        let sf = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let cupertino = CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312)
        let distance = CityGeocoder.distanceMeters(from: sf, to: cupertino)
        XCTAssertGreaterThan(distance, 25_000)
        XCTAssertEqual(CityGeocoder.distanceMeters(from: sf, to: sf), 0, accuracy: 1)
    }

    func testAwayBannerKeyChangesWithCityAndArea() {
        let sf = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let cupertino = CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312)
        let key = CityGeocoder.awayBannerKey(city: "San Francisco, CA", gps: cupertino)
        // A different city re-arms the banner.
        XCTAssertNotEqual(key, CityGeocoder.awayBannerKey(city: "Seattle, WA", gps: cupertino))
        // Moving to a new area re-arms it; staying in the same area does not.
        XCTAssertNotEqual(key, CityGeocoder.awayBannerKey(city: "San Francisco, CA", gps: sf))
        XCTAssertEqual(key, CityGeocoder.awayBannerKey(city: "San Francisco, CA", gps: cupertino))
    }
}
