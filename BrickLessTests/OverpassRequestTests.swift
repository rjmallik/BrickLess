import CoreLocation
import XCTest
@testable import PlayMatch

/// The Overpass request: the query the app sends for sport-tagged
/// pitches around a point, and the POST that carries it. The body
/// must be a properly form-encoded `data=` field — a raw body with
/// newlines and quotes is not valid form encoding — so the test
/// round-trips the body back to the exact query.
final class OverpassRequestTests: XCTestCase {

    private var sanFrancisco: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }

    func testOverpassQueryCoversLaunchSportsWithin25Kilometres() {
        let query = CourtStore.overpassQuery(around: sanFrancisco)
        for sport in CourtStore.launchSports {
            XCTAssertTrue(query.contains(sport), "query must cover \(sport)")
        }
        XCTAssertTrue(query.contains("\"leisure\"=\"pitch\""))
        XCTAssertTrue(query.contains("around:25000,37.7749,-122.4194"))
        XCTAssertTrue(query.contains("out center 200"))
    }

    func testOverpassQueryHonoursACustomRadius() {
        let query = CourtStore.overpassQuery(around: sanFrancisco, radiusMeters: 1000)
        XCTAssertTrue(query.contains("around:1000,37.7749,-122.4194"))
    }

    func testOverpassRequestIsPostToInterpreter() {
        let request = CourtStore.overpassRequest(around: sanFrancisco)
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.url?.absoluteString, "https://overpass-api.de/api/interpreter")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"),
                       "application/x-www-form-urlencoded")
    }

    func testOverpassRequestBodyRoundTripsToQuery() {
        let query = CourtStore.overpassQuery(around: sanFrancisco)
        let request = CourtStore.overpassRequest(around: sanFrancisco)
        let body = String(data: request?.httpBody ?? Data(), encoding: .utf8) ?? ""
        XCTAssertTrue(body.hasPrefix("data="), "body must be a data= form field")
        let encodedValue = String(body.dropFirst("data=".count))
        XCTAssertEqual(encodedValue.removingPercentEncoding, query)
    }

    func testOverpassRequestBodyHasNoRawNewlinesOrQuotes() {
        let request = CourtStore.overpassRequest(around: sanFrancisco)
        let body = String(data: request?.httpBody ?? Data(), encoding: .utf8) ?? ""
        XCTAssertFalse(body.contains("\n"), "raw newlines break the form field")
        XCTAssertFalse(body.contains("\""), "raw quotes break the form field")
    }
}
