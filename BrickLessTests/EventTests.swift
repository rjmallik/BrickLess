import XCTest
@testable import PlayMatch

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

    // MARK: - History

    func testPastEventsFiltersEndedAndSortsMostRecentFirst() {
        let endedFirst = makeEvent(id: "ended-first", start: testNow.addingTimeInterval(-7200), end: testNow.addingTimeInterval(-3600))
        let endedLater = makeEvent(id: "ended-later", start: testNow.addingTimeInterval(-3600), end: testNow.addingTimeInterval(-1800))
        let ongoing = makeEvent(id: "ongoing", start: testNow.addingTimeInterval(-3600), end: testNow.addingTimeInterval(3600))
        let upcoming = makeEvent(id: "upcoming", start: testNow.addingTimeInterval(3600), end: testNow.addingTimeInterval(7200))
        let past = EventStore.pastEvents([upcoming, endedFirst, ongoing, endedLater], now: testNow)
        XCTAssertEqual(past.compactMap { $0.id }, ["ended-later", "ended-first"])
    }

    func testPastEventsEmptyWhenNoneEnded() {
        let upcoming = makeEvent(id: "upcoming", start: testNow.addingTimeInterval(3600), end: testNow.addingTimeInterval(7200))
        XCTAssertTrue(EventStore.pastEvents([upcoming], now: testNow).isEmpty)
    }

    func testPastEventsIncludesGameEndingExactlyNow() {
        let endingNow = makeEvent(id: "ending-now", start: testNow.addingTimeInterval(-3600), end: testNow)
        XCTAssertEqual(EventStore.pastEvents([endingNow], now: testNow).compactMap { $0.id }, ["ending-now"])
    }

    func testEndedGameAppearsOnlyInHistory() {
        let ended = makeEvent(id: "ended", start: testNow.addingTimeInterval(-7200), end: testNow.addingTimeInterval(-3600))
        XCTAssertTrue(EventStore.upcomingEvents([ended], now: testNow).isEmpty)
        XCTAssertEqual(EventStore.pastEvents([ended], now: testNow).compactMap { $0.id }, ["ended"])
    }

    func testUpcomingGameNeverInHistory() {
        let upcoming = makeEvent(id: "upcoming", start: testNow.addingTimeInterval(3600), end: testNow.addingTimeInterval(7200))
        XCTAssertTrue(EventStore.pastEvents([upcoming], now: testNow).isEmpty)
        XCTAssertEqual(EventStore.upcomingEvents([upcoming], now: testNow).compactMap { $0.id }, ["upcoming"])
    }

    func testGameMovesFromUpcomingToHistoryAsTimePasses() {
        let game = makeEvent(id: "game", start: testNow.addingTimeInterval(3600), end: testNow.addingTimeInterval(7200))
        // Before it starts: upcoming, not history.
        XCTAssertEqual(EventStore.upcomingEvents([game], now: testNow).compactMap { $0.id }, ["game"])
        XCTAssertTrue(EventStore.pastEvents([game], now: testNow).isEmpty)
        // After it ends: history, not upcoming.
        let afterEnd = testNow.addingTimeInterval(7200)
        XCTAssertTrue(EventStore.upcomingEvents([game], now: afterEnd).isEmpty)
        XCTAssertEqual(EventStore.pastEvents([game], now: afterEnd).compactMap { $0.id }, ["game"])
    }

    func testIsEnded() {
        // endTime in the past (relative to the real clock) is ended;
        // endTime in the future is not. The epoch dates are fixed so
        // this never flakes around "now".
        let ended = makeEvent(id: "ended", start: Date(timeIntervalSince1970: 1_700_000_000), end: Date(timeIntervalSince1970: 1_700_003_600))
        XCTAssertTrue(ended.isEnded)
        let future = makeEvent(id: "future", start: Date(timeIntervalSince1970: 2_000_000_000), end: Date(timeIntervalSince1970: 2_000_003_600))
        XCTAssertFalse(future.isEnded)
    }
}
