import XCTest
@testable import PlayMatch

/// Direct-chat thread identity: the thread id is the two participant
/// UIDs sorted and joined, so either friend starting the chat lands in
/// the same thread, and only the two participants can see it.
final class DirectChatThreadTests: XCTestCase {

    private func makeThread(uids: [String] = ["uid-a", "uid-b"],
                            usernames: [String: String] = ["uid-a": "alice", "uid-b": "bob"],
                            lastMessageText: String? = nil,
                            lastMessageAt: Date? = nil) -> DirectChatThread {
        DirectChatThread(
            id: DirectChatStore.threadId(for: uids[0], uids[1]),
            participantUids: uids,
            participantUsernames: usernames,
            lastMessageText: lastMessageText,
            lastMessageAt: lastMessageAt,
            createdAt: testNow
        )
    }

    func testThreadIdIsOrderIndependent() {
        XCTAssertEqual(DirectChatStore.threadId(for: "uid-a", "uid-b"),
                       DirectChatStore.threadId(for: "uid-b", "uid-a"))
    }

    func testThreadIdDiffersForDifferentPairs() {
        XCTAssertNotEqual(DirectChatStore.threadId(for: "uid-a", "uid-b"),
                          DirectChatStore.threadId(for: "uid-a", "uid-c"))
    }

    func testParticipantUidsAreSorted() {
        XCTAssertEqual(DirectChatStore.participantUids(myUid: "zeta", friendUid: "alpha"),
                       ["alpha", "zeta"])
        XCTAssertEqual(DirectChatStore.participantUids(myUid: "alpha", friendUid: "zeta"),
                       ["alpha", "zeta"])
    }

    func testThreadIdMatchesSortedParticipants() {
        let uids = DirectChatStore.participantUids(myUid: "uid-b", friendUid: "uid-a")
        XCTAssertEqual(DirectChatStore.threadId(for: "uid-b", "uid-a"), uids.joined(separator: "_"))
    }

    func testBothParticipantsCanViewThread() {
        let thread = makeThread()
        XCTAssertTrue(DirectChatStore.canViewThread(thread, uid: "uid-a"))
        XCTAssertTrue(DirectChatStore.canViewThread(thread, uid: "uid-b"))
    }

    func testStrangerCannotViewThread() {
        let thread = makeThread()
        XCTAssertFalse(DirectChatStore.canViewThread(thread, uid: "uid-c"))
    }

    func testOtherUidAndUsernameFromMySide() {
        let thread = makeThread()
        XCTAssertEqual(thread.otherUid(myUid: "uid-a"), "uid-b")
        XCTAssertEqual(thread.otherUsername(myUid: "uid-a"), "bob")
        XCTAssertEqual(thread.otherUid(myUid: "uid-b"), "uid-a")
        XCTAssertEqual(thread.otherUsername(myUid: "uid-b"), "alice")
    }

    func testSortedThreadsMostRecentFirst() {
        let older = makeThread(uids: ["uid-a", "uid-b"],
                               lastMessageAt: testNow.addingTimeInterval(-3600))
        let newer = makeThread(uids: ["uid-a", "uid-c"],
                               lastMessageAt: testNow)
        let noMessages = makeThread(uids: ["uid-a", "uid-d"], lastMessageAt: nil)
        let sorted = DirectChatStore.sortedThreads([older, noMessages, newer])
        XCTAssertEqual(sorted.compactMap { $0.id },
                       [newer.id, older.id, noMessages.id].compactMap { $0 })
    }

    func testVisibleThreadsHidesBlockedOtherParticipant() {
        let withFriend = makeThread(uids: ["me", "friend"])
        let withBlocked = makeThread(uids: ["me", "blocked"])
        let visible = DirectChatStore.visibleThreads([withFriend, withBlocked],
                                                     myUid: "me", blockedUids: ["blocked"])
        XCTAssertEqual(visible.compactMap { $0.id }, [withFriend.id].compactMap { $0 })
    }

    func testVisibleThreadsKeepsAllWhenNobodyBlocked() {
        let threads = [makeThread(uids: ["me", "a"]), makeThread(uids: ["me", "b"])]
        XCTAssertEqual(DirectChatStore.visibleThreads(threads, myUid: "me", blockedUids: []).count, 2)
    }
}
