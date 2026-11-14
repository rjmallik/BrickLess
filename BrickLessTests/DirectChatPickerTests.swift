import XCTest
@testable import PlayMatch

/// Friend picker list for starting a chat: friends sorted by username,
/// with blocked users and the signed-in user left out.
final class DirectChatPickerTests: XCTestCase {

    func testPickerFriendsSortedByUsername() {
        let friends = [
            makeProfile(id: "uid-zoe", username: "zoe"),
            makeProfile(id: "uid-amy", username: "amy"),
            makeProfile(id: "uid-max", username: "max"),
        ]
        let picked = DirectChatStore.pickerFriends(friends, myUid: "me", blockedUids: [])
        XCTAssertEqual(picked.compactMap { $0.id }, ["uid-amy", "uid-max", "uid-zoe"])
    }

    func testPickerFriendsExcludesBlockedUsers() {
        let friends = [
            makeProfile(id: "uid-amy", username: "amy"),
            makeProfile(id: "uid-blocked", username: "blocked"),
        ]
        let picked = DirectChatStore.pickerFriends(friends, myUid: "me", blockedUids: ["uid-blocked"])
        XCTAssertEqual(picked.compactMap { $0.id }, ["uid-amy"])
    }

    func testPickerFriendsExcludesSelf() {
        let friends = [
            makeProfile(id: "me", username: "me"),
            makeProfile(id: "uid-amy", username: "amy"),
        ]
        let picked = DirectChatStore.pickerFriends(friends, myUid: "me", blockedUids: [])
        XCTAssertEqual(picked.compactMap { $0.id }, ["uid-amy"])
    }

    func testPickerFriendsEmptyStaysEmpty() {
        XCTAssertTrue(DirectChatStore.pickerFriends([], myUid: "me", blockedUids: []).isEmpty)
    }

    func testPickerFriendsSortIsCaseInsensitiveByLowercasedUsername() {
        let friends = [
            makeProfile(id: "uid-b", username: "Bob"),
            makeProfile(id: "uid-a", username: "amy"),
        ]
        let picked = DirectChatStore.pickerFriends(friends, myUid: "me", blockedUids: [])
        XCTAssertEqual(picked.compactMap { $0.id }, ["uid-a", "uid-b"])
    }
}
