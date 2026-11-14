import XCTest
@testable import PlayMatch

/// Sport tabs: labels and tag mapping, court and game filtering
/// (including multi-sport pitches), the create-form default sport,
/// GameEvent decoding without a sport field, and the Chats list.
final class SportTabsTests: XCTestCase {

    private func makeCourt(sport: String) -> Court {
        Court(id: "court-\(sport)", name: "Test court", sport: sport,
              latitude: 47.6062, longitude: -122.3321,
              surface: "", lit: false, indoor: false,
              source: "community", createdBy: nil)
    }

    // MARK: - Labels and tags

    func testLabelForTag() {
        XCTAssertEqual(SportTabs.label(forTag: "all"), "All")
        XCTAssertEqual(SportTabs.label(forTag: "basketball"), "Basketball")
        XCTAssertEqual(SportTabs.label(forTag: "soccer"), "Soccer")
        XCTAssertEqual(SportTabs.label(forTag: "football"), "American Football")
        XCTAssertEqual(SportTabs.label(forTag: "tennis"), "Tennis")
        XCTAssertEqual(SportTabs.label(forTag: "pickleball"), "Pickleball")
        XCTAssertEqual(SportTabs.label(forTag: "table_tennis"), "Table Tennis")
        XCTAssertEqual(SportTabs.label(forTag: "unknown"), "Basketball")
    }

    func testTagForDisplayName() {
        XCTAssertEqual(SportTabs.tag(forDisplayName: "Basketball"), "basketball")
        XCTAssertEqual(SportTabs.tag(forDisplayName: "Soccer"), "soccer")
        XCTAssertEqual(SportTabs.tag(forDisplayName: "American Football"), "football")
        XCTAssertEqual(SportTabs.tag(forDisplayName: "Tennis"), "tennis")
        XCTAssertEqual(SportTabs.tag(forDisplayName: "Pickleball"), "pickleball")
        XCTAssertEqual(SportTabs.tag(forDisplayName: "Table Tennis"), "table_tennis")
        XCTAssertNil(SportTabs.tag(forDisplayName: "Golf"))
        XCTAssertNil(SportTabs.tag(forDisplayName: ""))
    }

    func testLaunchSportsAreSixRealSports() {
        XCTAssertEqual(SportTabs.sports.map(\.tag),
                       ["basketball", "soccer", "football", "tennis", "pickleball", "table_tennis"])
        XCTAssertEqual(SportTabs.sports.map(\.label), UserProfile.allSports)
        XCTAssertFalse(SportTabs.realSports.contains("multi"))
        XCTAssertFalse(SportTabs.realSports.contains("all"))
    }

    // MARK: - Pin styles (ball icon + color per sport)

    func testPinStyleForEverySport() {
        // Ball symbols for the four ball sports; the figure symbol for
        // pickleball, table tennis and golf, which have no ball-only
        // SF Symbol. Every sport gets its own distinct color.
        let expected: [(tag: String, symbol: String, color: Color)] = [
            ("basketball", "basketball.fill", PlayMatchColors.basketball),
            ("soccer", "soccerball.fill", PlayMatchColors.soccer),
            ("football", "football.fill", PlayMatchColors.football),
            ("tennis", "tennisball.fill", PlayMatchColors.tennis),
            ("pickleball", "figure.pickleball", PlayMatchColors.pickleball),
            ("table_tennis", "figure.table.tennis", PlayMatchColors.tableTennis),
            ("golf", "figure.golf", PlayMatchColors.golf),
            ("multi", "figure.run", PlayMatchColors.multi),
        ]
        for (tag, symbol, color) in expected {
            let style = SportTabs.pinStyle(forTag: tag)
            XCTAssertEqual(style.symbol, symbol, "\(tag) pin symbol")
            XCTAssertEqual(style.color, color, "\(tag) pin color")
        }
        // The six launch sports plus golf and multi each get a different
        // color, so pins and chips read at a glance.
        let colors = Set(expected.map(\.color))
        XCTAssertEqual(colors.count, expected.count)
    }

    func testPinStyleFallsBackToBasketball() {
        let style = SportTabs.pinStyle(forTag: "unknown")
        XCTAssertEqual(style.symbol, "basketball.fill")
        XCTAssertEqual(style.color, PlayMatchColors.basketball)
    }

    func testColorForTag() {
        XCTAssertEqual(SportTabs.color(forTag: "all"), PlayMatchColors.brand)
        XCTAssertEqual(SportTabs.color(forTag: "basketball"), PlayMatchColors.basketball)
        XCTAssertEqual(SportTabs.color(forTag: "soccer"), PlayMatchColors.soccer)
        XCTAssertEqual(SportTabs.color(forTag: "football"), PlayMatchColors.football)
        XCTAssertEqual(SportTabs.color(forTag: "tennis"), PlayMatchColors.tennis)
        XCTAssertEqual(SportTabs.color(forTag: "pickleball"), PlayMatchColors.pickleball)
        XCTAssertEqual(SportTabs.color(forTag: "table_tennis"), PlayMatchColors.tableTennis)
        XCTAssertEqual(SportTabs.color(forTag: "golf"), PlayMatchColors.golf)
        XCTAssertEqual(SportTabs.color(forTag: "multi"), PlayMatchColors.multi)
    }

    // MARK: - Court filtering

    func testCourtMatchesAll() {
        XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: "basketball"), filter: "all"))
        XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: "soccer"), filter: "all"))
        XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: "multi"), filter: "all"))
    }

    func testCourtMatchesOwnSport() {
        // Every one of the six launch sports, individually.
        for tag in SportTabs.sports.map(\.tag) {
            XCTAssertTrue(SportTabs.courtMatches(makeCourt(sport: tag), filter: tag),
                          "\(tag) court should match the \(tag) tab")
        }
    }

    func testCourtDoesNotMatchOtherSport() {
        // Every sport as the non-matching case at least once: each
        // court's sport is checked against the next sport's tab.
        let tags = SportTabs.sports.map(\.tag)
        for (index, tag) in tags.enumerated() {
            let other = tags[(index + 1) % tags.count]
            XCTAssertFalse(SportTabs.courtMatches(makeCourt(sport: tag), filter: other),
                           "\(tag) court should not match the \(other) tab")
        }
    }

    func testMultiSportCourtMatchesAnySportTab() {
        let multi = makeCourt(sport: "multi")
        for tag in SportTabs.sports.map(\.tag) {
            XCTAssertTrue(SportTabs.courtMatches(multi, filter: tag), "multi should match \(tag)")
        }
    }

    // MARK: - Event filtering

    func testEventMatchesAll() {
        XCTAssertTrue(SportTabs.eventMatches(makeEvent(sport: "soccer"), filter: "all"))
    }

    func testEventMatchesOwnSport() {
        // Every one of the six launch sports, individually.
        for tag in SportTabs.sports.map(\.tag) {
            XCTAssertTrue(SportTabs.eventMatches(makeEvent(sport: tag), filter: tag),
                          "\(tag) game should match the \(tag) tab")
        }
    }

    func testEventDoesNotMatchOtherSport() {
        // Every sport as the non-matching case at least once: each
        // game's sport is checked against the next sport's tab.
        let tags = SportTabs.sports.map(\.tag)
        for (index, tag) in tags.enumerated() {
            let other = tags[(index + 1) % tags.count]
            XCTAssertFalse(SportTabs.eventMatches(makeEvent(sport: tag), filter: other),
                           "\(tag) game should not match the \(other) tab")
        }
    }

    // MARK: - Court tab and create-form default

    func testFilterForCourt() {
        XCTAssertEqual(SportTabs.filterForCourt(nil), "all")
        XCTAssertEqual(SportTabs.filterForCourt(makeCourt(sport: "soccer")), "soccer")
        XCTAssertEqual(SportTabs.filterForCourt(makeCourt(sport: "football")), "football")
        // A multi-sport pitch hosts games of any sport, so no single tab fits it.
        XCTAssertEqual(SportTabs.filterForCourt(makeCourt(sport: "multi")), "all")
    }

    func testDefaultSportFromCourt() {
        // Every one of the six launch sports, individually. The primary
        // is always a different sport, so the court sport must be what
        // wins.
        for tag in SportTabs.sports.map(\.tag) {
            let primary = tag == "basketball" ? "Soccer" : "Basketball"
            XCTAssertEqual(SportTabs.defaultSport(court: makeCourt(sport: tag),
                                                 primarySportDisplayName: primary), tag,
                           "court sport \(tag) should win over primary \(primary)")
        }
    }

    func testDefaultSportFallsBackToPrimarySport() {
        // A multi-sport pitch has no single sport, so the player's
        // primary sport is used instead.
        XCTAssertEqual(SportTabs.defaultSport(court: makeCourt(sport: "multi"),
                                             primarySportDisplayName: "Soccer"), "soccer")
        XCTAssertEqual(SportTabs.defaultSport(court: nil,
                                             primarySportDisplayName: "American Football"), "football")
    }

    func testDefaultSportFallsBackToBasketball() {
        XCTAssertEqual(SportTabs.defaultSport(court: makeCourt(sport: "multi"),
                                             primarySportDisplayName: nil), "basketball")
        XCTAssertEqual(SportTabs.defaultSport(court: nil, primarySportDisplayName: nil), "basketball")
        XCTAssertEqual(SportTabs.defaultSport(court: nil, primarySportDisplayName: "Golf"), "basketball")
    }

    // MARK: - GameEvent decoding without a sport field

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

    // MARK: - Chats list (upcoming joined games, soonest first)

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
