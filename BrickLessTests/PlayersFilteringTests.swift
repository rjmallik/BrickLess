import XCTest
@testable import PlayMatch

/// Player browse filtering covers ALL players, not just the loaded
/// pages (issue #4): the level filter is a server-side equality
/// filter described by `browseQueryPlan`, and the city filter is a
/// client-side substring applied while the scan fills a page
/// (`shouldFetchAnotherPage`). These tests cover that pure query/filter
/// logic without touching Firestore. The pre-existing
/// `filteredPlayers` tests live in FriendsAndPlayersTests.
final class PlayersFilteringTests: XCTestCase {

    // MARK: - Browse query plan

    func testPlanWithNoFiltersHasNoServerSideFilter() {
        let plan = PlayersStore.browseQueryPlan(levelFilter: "All", cityFilter: "")
        XCTAssertNil(plan.levelEquals)
        XCTAssertEqual(plan.citySubstring, "")
    }

    func testPlanWithLevelFilter() {
        let plan = PlayersStore.browseQueryPlan(levelFilter: "College", cityFilter: "")
        XCTAssertEqual(plan.levelEquals, "College")
        XCTAssertEqual(plan.citySubstring, "")
    }

    func testPlanTrimsCityFilter() {
        let plan = PlayersStore.browseQueryPlan(levelFilter: "All", cityFilter: "  Seattle  ")
        XCTAssertNil(plan.levelEquals)
        XCTAssertEqual(plan.citySubstring, "Seattle")
    }

    func testPlanWithWhitespaceOnlyCityIsNoCityFilter() {
        XCTAssertEqual(PlayersStore.browseQueryPlan(levelFilter: "All", cityFilter: "   ").citySubstring, "")
    }

    func testEveryLevelOfferedByTheUIProducesAServerSideFilter() {
        // The picker offers exactly PlayersStore.levels; each one must
        // map to an equality filter, or the level filter would silently
        // match nobody.
        for level in PlayersStore.levels {
            XCTAssertEqual(
                PlayersStore.browseQueryPlan(levelFilter: level, cityFilter: "").levelEquals,
                level
            )
        }
    }

    // MARK: - Fill-the-page scan

    func testKeepsFetchingWhilePageIsShortAndRawPagesRemain() {
        XCTAssertTrue(PlayersStore.shouldFetchAnotherPage(matchesSoFar: 0, pageSize: 20, rawPageWasFull: true))
        XCTAssertTrue(PlayersStore.shouldFetchAnotherPage(matchesSoFar: 19, pageSize: 20, rawPageWasFull: true))
    }

    func testStopsFetchingWhenPageIsFull() {
        XCTAssertFalse(PlayersStore.shouldFetchAnotherPage(matchesSoFar: 20, pageSize: 20, rawPageWasFull: true))
        XCTAssertFalse(PlayersStore.shouldFetchAnotherPage(matchesSoFar: 25, pageSize: 20, rawPageWasFull: true))
    }

    func testStopsFetchingWhenRawPagesRunOut() {
        XCTAssertFalse(PlayersStore.shouldFetchAnotherPage(matchesSoFar: 0, pageSize: 20, rawPageWasFull: false))
        XCTAssertFalse(PlayersStore.shouldFetchAnotherPage(matchesSoFar: 5, pageSize: 20, rawPageWasFull: false))
    }

    /// Simulates the fill-the-page scan over fake raw pages, using the
    /// production helpers: a city filter must find matches buried past
    /// the first raw page, not just in the first 20 profiles.
    func testScanFindsMatchesBuriedPastTheFirstRawPage() {
        let pageSize = 3
        let rawPages: [[UserProfile]] = [
            [
                makeProfile(id: "1", username: "aaa", city: "Seattle"),
                makeProfile(id: "2", username: "bbb", city: "Seattle"),
                makeProfile(id: "3", username: "ccc", city: "Seattle"),
            ],
            [
                makeProfile(id: "4", username: "ddd", city: "Tacoma"),
                makeProfile(id: "5", username: "eee", city: "Seattle"),
                makeProfile(id: "6", username: "fff", city: "Tacoma"),
            ],
            [
                makeProfile(id: "7", username: "ggg", city: "Tacoma"),
            ],
        ]
        var accumulated: [UserProfile] = []
        var hasMore = true
        for page in rawPages {
            let rawPageWasFull = page.count == pageSize
            let matches = PlayersStore.filteredPlayers(page, levelFilter: "All", cityFilter: "Tacoma")
            accumulated += matches
            if !PlayersStore.shouldFetchAnotherPage(matchesSoFar: accumulated.count, pageSize: pageSize, rawPageWasFull: rawPageWasFull) {
                hasMore = rawPageWasFull
                break
            }
        }
        // All three Tacoma players are found even though none was on
        // the first raw page; the short last page ends the scan.
        XCTAssertEqual(accumulated.compactMap { $0.id }, ["4", "6", "7"])
        XCTAssertFalse(hasMore)
    }

    /// A full page of matches stops the scan even when more raw pages
    /// exist, and hasMore stays true so the next page can be loaded.
    func testScanStopsOnAFullPageOfMatches() {
        let pageSize = 2
        let rawPages: [[UserProfile]] = [
            [
                makeProfile(id: "1", username: "aaa", city: "Tacoma"),
                makeProfile(id: "2", username: "bbb", city: "Tacoma"),
            ],
            [
                makeProfile(id: "3", username: "ccc", city: "Tacoma"),
            ],
        ]
        var accumulated: [UserProfile] = []
        var hasMore = false
        for page in rawPages {
            let rawPageWasFull = page.count == pageSize
            accumulated += PlayersStore.filteredPlayers(page, levelFilter: "All", cityFilter: "Tacoma")
            if !PlayersStore.shouldFetchAnotherPage(matchesSoFar: accumulated.count, pageSize: pageSize, rawPageWasFull: rawPageWasFull) {
                hasMore = rawPageWasFull
                break
            }
        }
        XCTAssertEqual(accumulated.compactMap { $0.id }, ["1", "2"])
        XCTAssertTrue(hasMore)
    }

    // MARK: - City filter edge cases (beyond FriendsAndPlayersTests)

    func testCityFilterWithSurroundingWhitespaceStillMatches() {
        let profiles = [makeProfile(id: "1", username: "a", city: "Seattle")]
        XCTAssertEqual(
            PlayersStore.filteredPlayers(profiles, levelFilter: "All", cityFilter: "  seattle ").compactMap { $0.id },
            ["1"]
        )
    }

    func testWhitespaceOnlyCityFilterMatchesEveryone() {
        let profiles = [
            makeProfile(id: "1", username: "a", city: "Seattle"),
            makeProfile(id: "2", username: "b", city: ""),
        ]
        XCTAssertEqual(
            PlayersStore.filteredPlayers(profiles, levelFilter: "All", cityFilter: "   ").count,
            2
        )
    }
}
