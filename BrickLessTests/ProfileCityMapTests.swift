import XCTest
@testable import PlayMatch

/// Profile city drives the map: the city name is normalized and
/// a set profile city wins the map centre over a GPS fix.
final class ProfileCityMapTests: XCTestCase {

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
}
