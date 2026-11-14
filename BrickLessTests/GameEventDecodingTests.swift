import XCTest
@testable import PlayMatch

/// GameEvent decoding: games posted before the sport field existed
/// decode as basketball; newer games decode with their sport.
final class GameEventDecodingTests: XCTestCase {

    func testGameEventDecodesWithoutSportAsBasketball() throws {
        // Games posted before the sport field existed have no "sport"
        // key; they must still decode, as basketball.
        let json = """
        {
          "id": "event-1",
          "courtId": "court-1", "courtName": "Cal Anderson Park",
          "creatorUid": "creator-uid", "creatorUsername": "rjhoops",
          "title": "Saturday run",
          "startTime": 1800003600, "endTime": 1800007200,
          "maxPlayers": 10, "playerUids": ["creator-uid"],
          "description": "", "createdAt": 1800000000
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let event = try decoder.decode(GameEvent.self, from: json)
        XCTAssertEqual(event.sport, "basketball")
    }

    func testGameEventDecodesWithSport() throws {
        let json = """
        {
          "id": "event-1",
          "courtId": "court-1", "courtName": "Cal Anderson Park", "sport": "soccer",
          "creatorUid": "creator-uid", "creatorUsername": "rjhoops",
          "title": "Saturday run",
          "startTime": 1800003600, "endTime": 1800007200,
          "maxPlayers": 10, "playerUids": ["creator-uid"],
          "description": "", "createdAt": 1800000000
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let event = try decoder.decode(GameEvent.self, from: json)
        XCTAssertEqual(event.sport, "soccer")
    }
}
