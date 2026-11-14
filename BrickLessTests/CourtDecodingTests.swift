import XCTest
@testable import PlayMatch

/// Court decoding: old community court docs decode as unverified
/// with no booking link; verified venues keep their link.
final class CourtDecodingTests: XCTestCase {

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
