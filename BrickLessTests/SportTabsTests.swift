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
}
