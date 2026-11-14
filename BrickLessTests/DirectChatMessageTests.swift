import XCTest
@testable import PlayMatch

/// Direct-chat messages: blank messages never send, and blocked
/// senders are hidden from everyone else.
final class DirectChatMessageTests: XCTestCase {

    private func makeDirectMessage(senderUid: String, text: String = "Let's go") -> DirectChatMessage {
        DirectChatMessage(
            id: UUID().uuidString,
            senderUid: senderUid,
            senderUsername: senderUid,
            text: text,
            createdAt: testNow
        )
    }

    func testTrimmedMessageTextTrimsWhitespace() {
        XCTAssertEqual(DirectChatStore.trimmedMessageText("  See you at 6  "), "See you at 6")
    }

    func testTrimmedMessageTextNilForBlank() {
        XCTAssertNil(DirectChatStore.trimmedMessageText(""))
        XCTAssertNil(DirectChatStore.trimmedMessageText("   "))
        XCTAssertNil(DirectChatStore.trimmedMessageText("\n\t"))
    }

    func testBlockedSendersHiddenFromDirectChat() {
        let messages = [
            makeDirectMessage(senderUid: "uid-a", text: "See you at 6"),
            makeDirectMessage(senderUid: "blocked-uid", text: "Hey"),
            makeDirectMessage(senderUid: "uid-b", text: "I'll bring a ball"),
        ]
        let visible = DirectChatStore.filterVisibleMessages(messages, blockedUids: ["blocked-uid"])
        XCTAssertEqual(visible.map { $0.senderUid }, ["uid-a", "uid-b"])
        XCTAssertEqual(visible.map { $0.text }, ["See you at 6", "I'll bring a ball"])
    }

    func testNoBlockedSendersKeepsAllMessagesInOrder() {
        let messages = [makeDirectMessage(senderUid: "a"), makeDirectMessage(senderUid: "b")]
        XCTAssertEqual(DirectChatStore.filterVisibleMessages(messages, blockedUids: []).count, 2)
    }

    func testAllBlockedSendersLeavesEmptyChat() {
        let messages = [makeDirectMessage(senderUid: "a"), makeDirectMessage(senderUid: "b")]
        XCTAssertTrue(DirectChatStore.filterVisibleMessages(messages, blockedUids: ["a", "b"]).isEmpty)
    }
}
