import XCTest
@testable import PlayMatch

/// Chats list: joined games that have ended drop out, a game in
/// progress stays, and the rest are soonest first.
final class UpcomingChatsTests: XCTestCase {

    func testUpcomingChatsFiltersEndedAndSortsSoonestFirst() {
        let ended = makeEvent(id: "ended", start: testNow.addingTimeInterval(-7200),
                              end: testNow.addingTimeInterval(-3600))
        let later = makeEvent(id: "later", start: testNow.addingTimeInterval(7200),
                              end: testNow.addingTimeInterval(10800))
        let sooner = makeEvent(id: "sooner", start: testNow.addingTimeInterval(3600),
                               end: testNow.addingTimeInterval(5400))
        let chats = EventStore.upcomingChats([ended, later, sooner], now: testNow)
        XCTAssertEqual(chats.compactMap { $0.id }, ["sooner", "later"])
    }

    func testUpcomingChatsKeepsGameInProgress() {
        let ongoing = makeEvent(id: "ongoing", start: testNow.addingTimeInterval(-3600),
                                end: testNow.addingTimeInterval(3600))
        XCTAssertEqual(EventStore.upcomingChats([ongoing], now: testNow).compactMap { $0.id }, ["ongoing"])
    }
}
