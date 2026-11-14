import XCTest
@testable import BrickLess

/// Pickup games: creation rules, joining (including the last spot),
/// and the upcoming list players actually see.
final class EventTests: XCTestCase {

    private func validate(title: String = "Saturday run", courtName: String = "Cal Anderson Park",
                          start: Date? = nil, end: Date? = nil, maxPlayers: Int = 10) -> String? {
        EventStore.validateEvent(title: title, courtName: courtName,
                                 start: start ?? testNow.addingTimeInterval(3600),
                                 end: end ?? testNow.addingTimeInterval(7200),
                                 maxPlayers: maxPlayers, now: testNow)
    }

    // MARK: - Creation validation

    func testValidEventPasses() {
        XCTAssertNil(validate())
    }

    func testEventPlayerCapBounds() {
        XCTAssertNil(validate(maxPlayers: 2))
        XCTAssertNil(validate(maxPlayers: 30))
        XCTAssertEqual(validate(maxPlayers: 1), "A game needs at least 2 players.")
        XCTAssertEqual(validate(maxPlayers: 31), "A game can have at most 30 players.")
    }

    func testEventRejectsEmptyTitleOrCourt() {
        XCTAssertEqual(validate(title: ""), "Give the game a title.")
        XCTAssertEqual(validate(courtName: ""), "Pick a court or type a court name.")
    }

    func testEventRejectsBadTimes() {
        XCTAssertEqual(validate(start: testNow.addingTimeInterval(7200), end: testNow.addingTimeInterval(3600)),
                       "End time must be after the start time.")
        XCTAssertEqual(validate(start: testNow.addingTimeInterval(-3600), end: testNow.addingTimeInterval(3600)),
                       "Pick a time in the future.")
    }

    // MARK: - Joining and the last spot

    func testJoinStatusOpenGame() {
        let event = makeEvent(maxPlayers: 10, playerUids: ["creator-uid"])
        XCTAssertEqual(event.joinStatus(for: "new-player"), .canJoin)
    }

    func testJoinStatusAlreadyJoined() {
        let event = makeEvent(maxPlayers: 10, playerUids: ["creator-uid", "player-2"])
        XCTAssertEqual(event.joinStatus(for: "player-2"), .alreadyJoined)
    }

    func testJoinStatusFullGame() {
        let event = makeEvent(maxPlayers: 2, playerUids: ["creator-uid", "player-2"])
        XCTAssertEqual(event.joinStatus(for: "player-3"), .full)
    }

    func testJoinStatusAlreadyJoinedBeatsFull() {
        // A player in a full game is "already joined", not "full".
        let event = makeEvent(maxPlayers: 2, playerUids: ["creator-uid", "player-2"])
        XCTAssertEqual(event.joinStatus(for: "player-2"), .alreadyJoined)
    }

    func testLastSpotRace() {
        // Two players grab for the last spot of a 2-player game.
        // Both decide against the same snapshot, so both see it open:
        // the decision is snapshot-based, which is why the Firestore
        // rules also cap playerUids at maxPlayers.
        let snapshot = makeEvent(maxPlayers: 2, playerUids: ["creator-uid"])
        XCTAssertEqual(snapshot.joinStatus(for: "player-a"), .canJoin)
        XCTAssertEqual(snapshot.joinStatus(for: "player-b"), .canJoin)

        // Once player A joins, the updated snapshot closes the spot.
        var afterAJoin = snapshot
        afterAJoin.playerUids.append("player-a")
        XCTAssertEqual(afterAJoin.joinStatus(for: "player-b"), .full)
        XCTAssertEqual(afterAJoin.joinStatus(for: "player-a"), .alreadyJoined)
    }

    func testIsFullAndHasPlayer() {
        let event = makeEvent(maxPlayers: 2, playerUids: ["creator-uid"])
        XCTAssertFalse(event.isFull)
        XCTAssertTrue(event.hasPlayer("creator-uid"))
        XCTAssertFalse(event.hasPlayer("someone-else"))

        var full = event
        full.playerUids.append("player-2")
        XCTAssertTrue(full.isFull)
    }

    // MARK: - Upcoming list

    func testUpcomingEventsFiltersPastAndSortsSoonestFirst() {
        let past = makeEvent(id: "past", start: testNow.addingTimeInterval(-3600), end: testNow.addingTimeInterval(-1800))
        let later = makeEvent(id: "later", start: testNow.addingTimeInterval(7200), end: testNow.addingTimeInterval(10800))
        let sooner = makeEvent(id: "sooner", start: testNow.addingTimeInterval(3600), end: testNow.addingTimeInterval(5400))
        let upcoming = EventStore.upcomingEvents([later, past, sooner], now: testNow)
        XCTAssertEqual(upcoming.compactMap { $0.id }, ["sooner", "later"])
    }

    func testUpcomingEventsEmptyWhenAllPast() {
        let past = makeEvent(id: "past", start: testNow.addingTimeInterval(-3600), end: testNow.addingTimeInterval(-1800))
        XCTAssertTrue(EventStore.upcomingEvents([past], now: testNow).isEmpty)
    }
}
