import SwiftUI
import XCTest
@testable import PlayMatch

/// Map pin styles: each sport's ball icon and colour, with a
/// basketball fallback for unknown tags.
final class SportPinStyleTests: XCTestCase {

    func testPinStyleForEverySport() {
        // Ball symbols for the four ball sports; the figure symbol for
        // pickleball, table tennis and golf, which have no ball-only
        // SF Symbol. Every sport gets its own distinct color.
        let expected: [(tag: String, symbol: String, color: Color)] = [
            ("basketball", "basketball.fill", PlayMatchColors.basketball),
            ("soccer", "soccerball", PlayMatchColors.soccer),
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
}
