import XCTest
import CoreLocation
@testable import BrickLess

/// Profile-setup location step: what the setup screen shows for each
/// authorization state. Pure mapping, no device needed. The key
/// guarantees: the prompt is offered only when iOS has never asked
/// (notDetermined), and signup never depends on location — denied or
/// restricted just shows the fallback note.
final class LocationSetupTests: XCTestCase {

    func testNotDeterminedOffersToEnable() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .notDetermined), .offerToEnable)
    }

    func testAuthorizedWhenInUseIsEnabled() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .authorizedWhenInUse), .enabled)
    }

    func testAuthorizedAlwaysIsEnabled() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .authorizedAlways), .enabled)
    }

    func testDeniedIsUnavailable() {
        // iOS will not re-prompt once denied, so there is no button:
        // the user finishes signup and the map's fallback covers it.
        XCTAssertEqual(LocationManager.setupPrompt(for: .denied), .unavailable)
    }

    func testRestrictedIsUnavailable() {
        XCTAssertEqual(LocationManager.setupPrompt(for: .restricted), .unavailable)
    }
}
