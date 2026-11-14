import XCTest
@testable import PlayMatch

/// Paid booking link gating: the "Book this [venue]" link shows
/// only for an indoor, verified venue with a valid booking link.
final class VenueBookingLinkTests: XCTestCase {

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
}
