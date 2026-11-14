import SwiftUI
import XCTest
@testable import PlayMatch

/// Bright glammy app background: the sunrise gradient in light mode
/// (warm white -> peach -> pale sky) and the faint brand-orange tint
/// over the system background in dark mode.
final class AppBackgroundTests: XCTestCase {

    func testLightGradientColorsAreSunrise() {
        XCTAssertEqual(AppBackground.lightGradientColors, [
            Color(red: 1.00, green: 0.99, blue: 0.96),
            Color(red: 1.00, green: 0.93, blue: 0.85),
            Color(red: 0.97, green: 0.95, blue: 1.00),
        ])
    }

    func testDarkGradientColorsAreBrandTintOverSystemBackground() {
        XCTAssertEqual(AppBackground.darkGradientColors, [
            PlayMatchColors.brand.opacity(0.18),
            PlayMatchColors.brand.opacity(0.06),
            Color(.systemBackground),
        ])
    }
}
