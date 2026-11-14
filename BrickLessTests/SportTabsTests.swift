import XCTest
@testable import PlayMatch

/// Sport tabs: labels and tag mapping.
final class SportTabsTests: XCTestCase {

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

    func testAllChipSymbols() {
        // The All chip shows all six sport icons together, never
        // the basketball-court icon: one icon per launch sport, in
        // tab order, each matching that sport's own chip icon.
        XCTAssertEqual(SportTabs.allChipSymbols, [
            "basketball.fill", "soccerball", "football.fill",
            "tennisball.fill", "figure.pickleball", "figure.table.tennis",
        ])
        XCTAssertEqual(SportTabs.allChipSymbols.count, SportTabs.sports.count)
        XCTAssertFalse(SportTabs.allChipSymbols.contains("sportscourt.fill"))
        XCTAssertFalse(SportTabs.allChipSymbols.contains("soccerball.fill"),
                       "soccerball.fill does not render; the soccer icon is soccerball")
        for (option, symbol) in zip(SportTabs.sports, SportTabs.allChipSymbols) {
            XCTAssertEqual(symbol, SportTabs.pinStyle(forTag: option.tag).symbol,
                           "\(option.tag) cluster icon must match its chip icon")
            XCTAssertFalse(symbol.isEmpty, "\(option.tag) cluster icon must not be empty")
        }
    }
}
