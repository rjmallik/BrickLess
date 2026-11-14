import XCTest
@testable import PlayMatch

/// Launch scope: the six real sports at launch, in both tag and
/// display-name form — every phase except golf (phase 4).
final class LaunchScopeTests: XCTestCase {

    func testLaunchSportsAreSixRealSports() {
        XCTAssertEqual(SportTabs.sports.map(\.tag),
                       ["basketball", "soccer", "football", "tennis", "pickleball", "table_tennis"])
        XCTAssertEqual(SportTabs.sports.map(\.label), UserProfile.allSports)
        XCTAssertFalse(SportTabs.realSports.contains("multi"))
        XCTAssertFalse(SportTabs.realSports.contains("all"))
    }

    /// All phases except golf (phase 4): basketball, soccer + American
    /// football, tennis + pickleball + table tennis. The map list is in
    /// OSM tag form, the signup list in display-name form.
    func testLaunchSportsAllPhasesExceptGolf() {
        XCTAssertEqual(CourtStore.launchSports,
                       ["basketball", "soccer", "american_football",
                        "tennis", "pickleball", "table_tennis"])
        XCTAssertEqual(UserProfile.allSports,
                       ["Basketball", "Soccer", "American Football",
                        "Tennis", "Pickleball", "Table Tennis"])
        XCTAssertFalse(CourtStore.launchSports.contains("golf"))
        XCTAssertFalse(UserProfile.allSports.contains("Golf"))
    }
}
