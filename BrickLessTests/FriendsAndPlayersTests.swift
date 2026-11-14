import XCTest
@testable import PlayMatch

/// Friends search and player discovery: query rules, blocked users
/// never appearing, and the level/city filters.
final class FriendsAndPlayersTests: XCTestCase {

    // MARK: - Username search query

    func testNormalizedSearchQuery() {
        XCTAssertEqual(FriendsStore.normalizedSearchQuery("RJ"), "rj")
        XCTAssertEqual(FriendsStore.normalizedSearchQuery("  rj  "), "rj")
        XCTAssertEqual(FriendsStore.normalizedSearchQuery("rj"), "rj")
    }

    func testShortSearchQueryIsNil() {
        XCTAssertNil(FriendsStore.normalizedSearchQuery("r"))
        XCTAssertNil(FriendsStore.normalizedSearchQuery(""))
        XCTAssertNil(FriendsStore.normalizedSearchQuery("   "))
    }

    // MARK: - Search results filtering

    func testFilterSearchResultsRemovesSelfAndBlocked() {
        let me = makeProfile(id: "me", username: "me")
        let blocked = makeProfile(id: "blocked-uid", username: "blocked")
        let other = makeProfile(id: "other-uid", username: "other")
        let results = FriendsStore.filterSearchResults([me, blocked, other], myUid: "me", blockedUids: ["blocked-uid"])
        XCTAssertEqual(results.compactMap { $0.id }, ["other-uid"])
    }

    func testFilterSearchResultsKeepsEveryoneWhenNothingBlocked() {
        let a = makeProfile(id: "a", username: "aaa")
        let b = makeProfile(id: "b", username: "bbb")
        XCTAssertEqual(FriendsStore.filterSearchResults([a, b], myUid: "me", blockedUids: []).count, 2)
    }

    // MARK: - Player discovery filters

    private func players() -> [UserProfile] {
        [
            makeProfile(id: "1", username: "seattle-pro", highestLevel: "College", city: "Seattle"),
            makeProfile(id: "2", username: "seattle-rec", highestLevel: "Recreational", city: "Seattle"),
            makeProfile(id: "3", username: "tacoma-college", highestLevel: "College", city: "Tacoma"),
            makeProfile(id: "4", username: "no-level", highestLevel: nil, city: "Seattle"),
        ]
    }

    func testNoFiltersReturnsEveryone() {
        XCTAssertEqual(PlayersStore.filteredPlayers(players(), levelFilter: "All", cityFilter: "").count, 4)
    }

    func testLevelFilter() {
        let filtered = PlayersStore.filteredPlayers(players(), levelFilter: "College", cityFilter: "")
        XCTAssertEqual(filtered.compactMap { $0.id }, ["1", "3"])
    }

    func testCityFilterIsCaseInsensitiveSubstring() {
        XCTAssertEqual(PlayersStore.filteredPlayers(players(), levelFilter: "All", cityFilter: "seattle").compactMap { $0.id }, ["1", "2", "4"])
        XCTAssertEqual(PlayersStore.filteredPlayers(players(), levelFilter: "All", cityFilter: "SEA").compactMap { $0.id }, ["1", "2", "4"])
        XCTAssertEqual(PlayersStore.filteredPlayers(players(), levelFilter: "All", cityFilter: "tac").compactMap { $0.id }, ["3"])
    }

    func testLevelAndCityFiltersCombine() {
        XCTAssertEqual(PlayersStore.filteredPlayers(players(), levelFilter: "College", cityFilter: "Seattle").compactMap { $0.id }, ["1"])
    }

    func testLevelFilterExcludesProfilesWithoutALevel() {
        // "no-level" has no highestLevel, so a level filter drops it.
        XCTAssertFalse(PlayersStore.filteredPlayers(players(), levelFilter: "College", cityFilter: "").contains { $0.id == "4" })
    }
}
