import XCTest
@testable import PlayMatch

/// Deleting a game deletes its chat too: message IDs are chunked into
/// batches of at most 500 (the Firestore batch limit), and the event
/// doc is always deleted last. The Firestore calls themselves are not
/// unit-tested here; these tests pin the pure chunking and ordering
/// rules deleteEvent relies on.
final class GameDeletionTests: XCTestCase {

    private func messageIds(_ count: Int) -> [String] {
        (0..<count).map { "msg-\($0)" }
    }

    // MARK: - Batching

    func testBatchLimitIs500() {
        XCTAssertEqual(EventStore.maxBatchWrites, 500)
    }

    func testEmptyChatNeedsNoBatches() {
        XCTAssertTrue(EventStore.messageDeletionBatches([]).isEmpty)
    }

    func testSmallChatIsOneBatch() {
        XCTAssertEqual(EventStore.messageDeletionBatches(["a", "b", "c"]), [["a", "b", "c"]])
    }

    func testExactly500MessagesIsOneBatch() {
        let batches = EventStore.messageDeletionBatches(messageIds(500))
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches[0].count, 500)
    }

    func test501MessagesSplitIntoTwoBatches() {
        let batches = EventStore.messageDeletionBatches(messageIds(501))
        XCTAssertEqual(batches.map { $0.count }, [500, 1])
    }

    func testLargeChatChunksTo500AndKeepsOrder() {
        let ids = messageIds(1234)
        let batches = EventStore.messageDeletionBatches(ids)
        XCTAssertEqual(batches.map { $0.count }, [500, 500, 234])
        XCTAssertEqual(batches.flatMap { $0 }, ids)
    }

    func testNoBatchExceedsLimit() {
        let batches = EventStore.messageDeletionBatches(messageIds(2500))
        XCTAssertTrue(batches.allSatisfy { $0.count <= EventStore.maxBatchWrites })
        XCTAssertEqual(batches.count, 5)
    }

    // MARK: - Deletion order

    func testEventWithNoMessagesDeletesOnlyTheEventDoc() {
        XCTAssertEqual(EventStore.deletionSteps(messageCount: 0), [.deleteEventDocument])
    }

    func testEventDocIsAlwaysDeletedLast() {
        for count in [1, 500, 501, 1200] {
            let steps = EventStore.deletionSteps(messageCount: count)
            XCTAssertEqual(steps.last, .deleteEventDocument, "messageCount \(count)")
            XCTAssertTrue(steps.dropLast().allSatisfy {
                if case .deleteMessageBatch = $0 { return true }
                return false
            }, "messageCount \(count)")
        }
    }

    func testLargeChatDeletesInThreeBatchesThenTheEvent() {
        XCTAssertEqual(EventStore.deletionSteps(messageCount: 1200), [
            .deleteMessageBatch(batchIndex: 0),
            .deleteMessageBatch(batchIndex: 1),
            .deleteMessageBatch(batchIndex: 2),
            .deleteEventDocument,
        ])
    }

    func testBatchCountMatchesChunking() {
        // The step list and the chunking agree on how many batches a
        // chat of a given size needs.
        for count in [0, 1, 499, 500, 501, 1000, 1001] {
            let batchSteps = EventStore.deletionSteps(messageCount: count)
                .filter { if case .deleteMessageBatch = $0 { return true }; return false }
            XCTAssertEqual(batchSteps.count,
                           EventStore.messageDeletionBatches(messageIds(count)).count,
                           "messageCount \(count)")
        }
    }
}
