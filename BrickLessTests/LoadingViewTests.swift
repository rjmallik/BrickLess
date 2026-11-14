import XCTest
@testable import PlayMatch

/// Loading screen: shows the new PlayMatch icon full-screen on the
/// icon's own orange background (never the old BrickLess logo).
final class LoadingViewTests: XCTestCase {

    func testDefaultImageIsTheNewPlayMatchIcon() {
        XCTAssertEqual(LoadingView().logoImageName, LoadingView.playMatchIconImageName)
        XCTAssertEqual(LoadingView().logoImageName, "PlayMatchIcon")
    }

    func testDefaultDurationIsUnchanged() {
        XCTAssertEqual(LoadingView().duration, 2)
    }
}
