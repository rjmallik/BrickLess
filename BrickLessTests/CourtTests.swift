import XCTest
import CoreLocation
@testable import PlayMatch

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

    // MARK: - Venue words

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

    // MARK: - Paid booking link gating

    private func makeVenue(indoor: Bool, verified: Bool, bookingURL: String?) -> Court {
        Court(id: "venue", name: "Test venue", sport: "basketball",
              latitude: 47.6062, longitude: -122.3321,
              surface: "", lit: false, indoor: indoor,
              bookingURL: bookingURL, verified: verified,
              source: "community", createdBy: "user-1")
    }

    /// The paid "Book this [venue]" link shows only when the venue is
    /// indoor, verified, and carries a booking link. Every condition
    /// failing hides it.
    func testCanShowBookingLinkNeedsIndoorVerifiedAndLink() {
        let link = "https://example.com/book"
        // All three conditions: shown.
        XCTAssertTrue(Court.canShowBookingLink(makeVenue(indoor: true, verified: true, bookingURL: link)))
        // Outdoor: hidden, even verified with a link.
        XCTAssertFalse(Court.canShowBookingLink(makeVenue(indoor: false, verified: true, bookingURL: link)))
        // Unverified: hidden, even indoor with a link (a fake venue
        // cannot carry a scam booking link until we verify it).
        XCTAssertFalse(Court.canShowBookingLink(makeVenue(indoor: true, verified: false, bookingURL: link)))
        // No link: hidden, even indoor and verified.
        XCTAssertFalse(Court.canShowBookingLink(makeVenue(indoor: true, verified: true, bookingURL: nil)))
        // Blank link: hidden.
        XCTAssertFalse(Court.canShowBookingLink(makeVenue(indoor: true, verified: true, bookingURL: "   ")))
        // Malformed link: hidden.
        XCTAssertFalse(Court.canShowBookingLink(makeVenue(indoor: true, verified: true, bookingURL: "not a link")))
    }

    func testValidatedBookingURLString() {
        XCTAssertEqual(Court.validatedBookingURLString("https://example.com/book")?.absoluteString,
                       "https://example.com/book")
        XCTAssertEqual(Court.validatedBookingURLString("http://example.com/book")?.absoluteString,
                       "http://example.com/book")
        XCTAssertNil(Court.validatedBookingURLString(nil))
        XCTAssertNil(Court.validatedBookingURLString(""))
        XCTAssertNil(Court.validatedBookingURLString("   "))
        XCTAssertNil(Court.validatedBookingURLString("not a link"))
        XCTAssertNil(Court.validatedBookingURLString("ftp://example.com/book"))
        XCTAssertNil(Court.validatedBookingURLString("https://"))
        // Leading/trailing whitespace is trimmed, not rejected.
        XCTAssertEqual(Court.validatedBookingURLString("  https://example.com/book  ")?.absoluteString,
                       "https://example.com/book")
    }

    // MARK: - Verified defaults (decoding)

    /// An old community court doc has no bookingURL or verified field:
    /// it decodes as unverified with no booking link (pending review).
    func testOldCommunityCourtDecodesAsUnverified() throws {
        let json = """
        {"id":"c1","name":"Park court","sport":"basketball",
         "latitude":47.6062,"longitude":-122.3321,"surface":"",
         "lit":false,"indoor":false,"source":"community",
         "createdBy":"user-1","gridKey":"4760_-12233"}
        """.data(using: .utf8)!
        let court = try JSONDecoder().decode(Court.self, from: json)
        XCTAssertFalse(court.verified)
        XCTAssertNil(court.bookingURL)
    }

    /// A verified community venue decodes with its booking link intact.
    func testVerifiedCommunityCourtDecodesWithBookingLink() throws {
        let json = """
        {"id":"c2","name":"Indoor arena","sport":"basketball",
         "latitude":47.6062,"longitude":-122.3321,"surface":"wood",
         "lit":true,"indoor":true,"bookingURL":"https://example.com/book",
         "verified":true,"source":"community",
         "createdBy":"user-1","gridKey":"4760_-12233"}
        """.data(using: .utf8)!
        let court = try JSONDecoder().decode(Court.self, from: json)
        XCTAssertTrue(court.verified)
        XCTAssertEqual(court.bookingURL, "https://example.com/book")
        XCTAssertTrue(Court.canShowBookingLink(court))
    }
}
