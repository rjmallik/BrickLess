import SwiftUI
import XCTest
@testable import PlayMatch

/// Venue loading indicator: the line always reads "Finding…"
/// (never "Loading"), the icon is a sports ball only (never a
/// person figure), and an icon is always shown at every step of
/// the cycle. The loading indicator uses its own ball-only
/// mapping, SportTabs.loadingBallStyle — not the map-pin mapping,
/// which still uses figure.* symbols for some sports.
final class VenueLoadingTests: XCTestCase {

    func testLoadingTextIsAlwaysFindingNeverLoading() {
        for index in 0..<20 {
            let text = VenueLoadingCycle.text(at: index)
            XCTAssertEqual(text, "Finding…", "step \(index)")
            XCTAssertFalse(text.contains("Loading"), "step \(index) must not say Loading")
        }
    }

    func testLoadingSymbolsAreBallOnlyForEverySport() {
        // The four ball sports use their own ball; pickleball, table
        // tennis and golf have no ball-only SF Symbol, so they use
        // the generic ball "circle.fill" in their own sport color.
        let expected: [(tag: String, symbol: String, color: Color)] = [
            ("basketball", "basketball.fill", PlayMatchColors.basketball),
            ("soccer", "soccerball", PlayMatchColors.soccer),
            ("football", "football.fill", PlayMatchColors.football),
            ("tennis", "tennisball.fill", PlayMatchColors.tennis),
            ("pickleball", "circle.fill", PlayMatchColors.pickleball),
            ("table_tennis", "circle.fill", PlayMatchColors.tableTennis),
            ("golf", "circle.fill", PlayMatchColors.golf),
        ]
        for (tag, symbol, color) in expected {
            let style = SportTabs.loadingBallStyle(forTag: tag)
            XCTAssertEqual(style.symbol, symbol, "\(tag) loading symbol")
            XCTAssertEqual(style.color, color, "\(tag) loading color")
            XCTAssertFalse(style.symbol.contains("figure"),
                           "\(tag) loading symbol must not be a person figure")
            XCTAssertFalse(style.symbol.isEmpty, "\(tag) loading symbol must not be empty")
        }
    }

    func testLoadingCycleNeverShowsAFigureSymbol() {
        let forbidden = ["figure.pickleball", "figure.table.tennis",
                         "figure.golf", "figure.run"]
        for index in 0..<21 {
            let symbol = VenueLoadingCycle.symbol(at: index)
            XCTAssertFalse(symbol.contains("figure"),
                           "step \(index) showed a person figure: \(symbol)")
            XCTAssertFalse(forbidden.contains(symbol), "step \(index) showed \(symbol)")
        }
    }

    func testLoadingCycleAlwaysShowsAnIcon() {
        // An icon at every step, including across the wrap: the
        // symbol is non-empty at every cycle step, so the indicator
        // can never be in a loading state with no icon visible.
        for index in 0..<21 {
            XCTAssertFalse(VenueLoadingCycle.symbol(at: index).isEmpty,
                           "step \(index) has no icon")
        }
    }

    func testLoadingBallStyleFallsBackToBasketball() {
        for tag in ["unknown", "multi", ""] {
            let style = SportTabs.loadingBallStyle(forTag: tag)
            XCTAssertEqual(style.symbol, "basketball.fill", "fallback for \(tag)")
            XCTAssertEqual(style.color, PlayMatchColors.basketball)
            XCTAssertFalse(style.symbol.contains("figure"))
            XCTAssertFalse(style.symbol.isEmpty)
        }
    }

    func testLoadingCycleTagsCoverAllSevenSportsThenRepeat() {
        let tags = (0..<7).map { VenueLoadingCycle.tag(at: $0) }
        XCTAssertEqual(tags, ["basketball", "soccer", "football", "tennis",
                              "pickleball", "table_tennis", "golf"])
        // The cycle wraps: step 7 is basketball again.
        XCTAssertEqual(VenueLoadingCycle.tag(at: 7), "basketball")
        XCTAssertEqual(VenueLoadingCycle.tag(at: 8), "soccer")
    }
}
