import XCTest
@testable import PlayMatch

/// Event group chat: only joined players can see it and send in it,
/// and blocked senders are hidden from everyone else.
final class ChatTests: XCTestCase {

    func testJoinedPlayersCanViewChat() {
        let event = makeEvent(playerUids: ["creator-uid", "player-2"])
        XCTAssertTrue(EventStore.canViewChat(event: event, uid: "creator-uid"))
        XCTAssertTrue(EventStore.canViewChat(event: event, uid: "player-2"))
    }

    func testNonPlayersCannotViewChat() {
        let event = makeEvent(playerUids: ["creator-uid"])
        XCTAssertFalse(EventStore.canViewChat(event: event, uid: "stranger"))
    }

    func testBlockedSendersHiddenFromChat() {
        let messages = [
            makeMessage(senderUid: "creator-uid", text: "See you at 6"),
            makeMessage(senderUid: "blocked-uid", text: "Hey"),
            makeMessage(senderUid: "player-2", text: "I'll bring a ball"),
        ]
        let visible = EventStore.filterVisibleMessages(messages, blockedUids: ["blocked-uid"])
        XCTAssertEqual(visible.map { $0.senderUid }, ["creator-uid", "player-2"])
        XCTAssertEqual(visible.map { $0.text }, ["See you at 6", "I'll bring a ball"])
    }

    func testNoBlockedSendersKeepsAllMessagesInOrder() {
        let messages = [makeMessage(senderUid: "a"), makeMessage(senderUid: "b")]
        XCTAssertEqual(EventStore.filterVisibleMessages(messages, blockedUids: []).count, 2)
    }

    func testAllBlockedSendersLeavesEmptyChat() {
        let messages = [makeMessage(senderUid: "a"), makeMessage(senderUid: "b")]
        XCTAssertTrue(EventStore.filterVisibleMessages(messages, blockedUids: ["a", "b"]).isEmpty)
    }
}
