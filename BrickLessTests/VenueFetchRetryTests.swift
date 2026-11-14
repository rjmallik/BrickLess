import CoreLocation
import XCTest
@testable import PlayMatch

/// A failed venues fetch must be retryable: one bad Overpass
/// response (at capacity, offline, bad JSON) used to poison the
/// per-cell cache, so the map stayed empty for that city until the
/// app was killed — re-saving the same city, reopening the map,
/// and switching tabs all silently did nothing. The retry rule
/// below is what guarantees those actions start a fresh fetch.
final class VenueFetchRetryTests: XCTestCase {

    func testSuccessfulCellIsNotRefetched() {
        XCTAssertFalse(CourtStore.shouldStartFetch(key: "3777_-12241",
                                                   lastSuccessfulKey: "3777_-12241",
                                                   inFlightKey: nil))
    }

    func testFailedCellStartsAFreshFetch() {
        // No successful key: the last fetch for this cell failed
        // (or never ran), so a new fetch must start.
        XCTAssertTrue(CourtStore.shouldStartFetch(key: "3777_-12241",
                                                  lastSuccessfulKey: "",
                                                  inFlightKey: nil))
        // A different cell succeeded; this cell still fetches.
        XCTAssertTrue(CourtStore.shouldStartFetch(key: "3777_-12241",
                                                  lastSuccessfulKey: "4760_-12233",
                                                  inFlightKey: nil))
    }

    func testInFlightFetchIsNotDuplicated() {
        XCTAssertFalse(CourtStore.shouldStartFetch(key: "3777_-12241",
                                                   lastSuccessfulKey: "",
                                                   inFlightKey: "3777_-12241"))
        // A different cell in flight does not block this one.
        XCTAssertTrue(CourtStore.shouldStartFetch(key: "3777_-12241",
                                                  lastSuccessfulKey: "",
                                                  inFlightKey: "4760_-12233"))
    }

    func testFetchCacheKeyMatchesCourtGridKey() {
        let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        XCTAssertEqual(CourtStore.fetchCacheKey(for: sanFrancisco),
                       Court.gridKey(latitude: 37.7749, longitude: -122.4194))
        XCTAssertEqual(CourtStore.fetchCacheKey(for: sanFrancisco), "3777_-12241")
    }

    func testOverpassRetriesThreeAttemptsTotal() {
        XCTAssertEqual(CourtStore.overpassMaxAttempts, 3)
    }

    func testOverpassRetryBackoffGrows() {
        XCTAssertEqual(CourtStore.overpassRetryDelaySeconds(forAttempt: 1), 1)
        XCTAssertEqual(CourtStore.overpassRetryDelaySeconds(forAttempt: 2), 2)
        XCTAssertEqual(CourtStore.overpassRetryDelaySeconds(forAttempt: 3), 0)
    }

    func testVenueFetchErrorMessageExplainsAndOffersRetry() {
        let message = CourtStore.venueFetchErrorMessage
        XCTAssertFalse(message.isEmpty)
        XCTAssertTrue(message.contains("try again"),
                      "the error must tell the player trying again can fix it")
    }
}
