import XCTest
@testable import BrickLess

/// Delete Account cleanup (issue #2): the pure helpers behind it.
/// No Firebase here: chunking and the cleanup-query list are pure, so
/// these tests pin down the batch limit and exactly which collections
/// get cleaned up, without touching a real database.
final class DeleteAccountTests: XCTestCase {

    // MARK: - Batch limit

    func testBatchLimitIsFirestoreLimit() {
        // Firestore allows at most 500 writes per batch.
        XCTAssertEqual(SessionStore.deleteAccountBatchLimit, 500)
    }

    // MARK: - Chunking

    func testChunkEmptyList() {
        XCTAssertEqual(SessionStore.chunked([Int](), size: 500), [])
    }

    func testChunkFewerThanOneBatch() {
        XCTAssertEqual(SessionStore.chunked([1, 2, 3], size: 500), [[1, 2, 3]])
    }

    func testChunkExactlyOneBatch() {
        let items = Array(1...500)
        XCTAssertEqual(SessionStore.chunked(items, size: 500), [items])
    }

    func testChunkOneOverTheLimitSplits() {
        let items = Array(1...501)
        let chunks = SessionStore.chunked(items, size: 500)
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0].count, 500)
        XCTAssertEqual(chunks[1], [501])
    }

    func testChunkTwoFullBatches() {
        let chunks = SessionStore.chunked(Array(1...1000), size: 500)
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks.map(\.count), [500, 500])
    }

    func testChunkRemainderGoesInLastChunk() {
        let chunks = SessionStore.chunked(Array(1...1200), size: 500)
        XCTAssertEqual(chunks.map(\.count), [500, 500, 200])
        // Nothing lost, nothing duplicated, order preserved.
        XCTAssertEqual(chunks.flatMap { $0 }, Array(1...1200))
    }

    func testChunkNeverExceedsLimit() {
        let chunks = SessionStore.chunked(Array(1...2345), size: SessionStore.deleteAccountBatchLimit)
        XCTAssertTrue(chunks.allSatisfy { $0.count <= SessionStore.deleteAccountBatchLimit })
        XCTAssertEqual(chunks.flatMap { $0 }, Array(1...2345))
    }

    func testChunkNonPositiveSizeIsEmpty() {
        XCTAssertEqual(SessionStore.chunked([1, 2, 3], size: 0), [])
        XCTAssertEqual(SessionStore.chunked([1, 2, 3], size: -1), [])
    }

    // MARK: - Cleanup coverage

    func testCleanupCoversFriendshipsBothDirections() {
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "uid-1")
        XCTAssertTrue(queries.contains(
            SessionStore.DeleteAccountQuery(collectionPath: "friendships", field: "fromUid", value: "uid-1")))
        XCTAssertTrue(queries.contains(
            SessionStore.DeleteAccountQuery(collectionPath: "friendships", field: "toUid", value: "uid-1")))
    }

    func testCleanupCoversBookingsByBooker() {
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "uid-1")
        XCTAssertTrue(queries.contains(
            SessionStore.DeleteAccountQuery(collectionPath: "bookings", field: "bookedBy", value: "uid-1")))
    }

    func testCleanupCoversBlocksSubcollection() {
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "uid-1")
        XCTAssertTrue(queries.contains(
            SessionStore.DeleteAccountQuery(collectionPath: "blocks/uid-1/blocked", field: nil, value: nil)))
    }

    func testCleanupCoversReportsByReporter() {
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "uid-1")
        XCTAssertTrue(queries.contains(
            SessionStore.DeleteAccountQuery(collectionPath: "reports", field: "reporterUid", value: "uid-1")))
    }

    func testCleanupCoversExactlyFiveQueries() {
        XCTAssertEqual(SessionStore.deleteAccountCleanupQueries(uid: "uid-1").count, 5)
    }

    func testCleanupUsesTheGivenUidEverywhere() {
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "some-other-uid")
        XCTAssertTrue(queries.allSatisfy { $0.value == "some-other-uid" || $0.collectionPath.contains("some-other-uid") })
        XCTAssertFalse(queries.contains { $0.value == "uid-1" || $0.collectionPath.contains("uid-1") })
    }

    func testCleanupDoesNotTouchEvents() {
        // Out of scope on purpose: events the user created need
        // chat-message cleanup too (a separate fix), and removing them
        // from events they joined is a follow-up. Nothing here may
        // delete or rewrite another user's event.
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "uid-1")
        XCTAssertFalse(queries.contains { $0.collectionPath.hasPrefix("events") })
    }

    func testCleanupDoesNotTouchProfilesOrUsernames() {
        // Profile + username reservation are deleted separately, before
        // cleanup runs; the cleanup list must not re-delete them or
        // touch any other collection.
        let queries = SessionStore.deleteAccountCleanupQueries(uid: "uid-1")
        let paths = Set(queries.map(\.collectionPath))
        XCTAssertFalse(paths.contains("users"))
        XCTAssertFalse(paths.contains("usernames"))
        XCTAssertTrue(paths.isSubset(of: ["friendships", "bookings", "blocks/uid-1/blocked", "reports"]))
    }
}
