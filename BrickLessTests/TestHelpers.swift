import Foundation
@testable import BrickLess

/// Shared builders for the BrickLess unit tests. All dates are built
/// off one fixed reference point so time-based tests are deterministic
/// and never flaky around "now".

/// Fixed reference "now" for tests: 2027-01-15 08:00 UTC.
let testNow = Date(timeIntervalSince1970: 1_800_000_000)

func makeProfile(
    id: String = "uid-1",
    username: String = "rjhoops",
    highestLevel: String? = nil,
    city: String = "",
    age: Int? = nil,
    heightInches: Int? = nil
) -> UserProfile {
    UserProfile(
        id: id,
        username: username,
        usernameLower: username.lowercased(),
        email: "rj@example.com",
        displayName: username,
        position: "Any",
        skillLevel: "Beginner",
        city: city,
        sports: ["Basketball"],
        profileComplete: true,
        age: age,
        heightInches: heightInches,
        highestLevel: highestLevel,
        createdAt: testNow,
        updatedAt: testNow
    )
}

func makeEvent(
    id: String = "event-1",
    maxPlayers: Int = 10,
    playerUids: [String] = ["creator-uid"],
    start: Date = testNow.addingTimeInterval(3600),
    end: Date = testNow.addingTimeInterval(7200)
) -> GameEvent {
    GameEvent(
        id: id,
        courtId: "court-1",
        courtName: "Cal Anderson Park",
        creatorUid: "creator-uid",
        creatorUsername: "rjhoops",
        title: "Saturday run",
        startTime: start,
        endTime: end,
        maxPlayers: maxPlayers,
        playerUids: playerUids,
        description: "",
        createdAt: testNow
    )
}

func makeMessage(senderUid: String, text: String = "Let's go") -> EventMessage {
    EventMessage(
        id: UUID().uuidString,
        senderUid: senderUid,
        senderUsername: senderUid,
        text: text,
        createdAt: testNow
    )
}
