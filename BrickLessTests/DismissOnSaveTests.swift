import XCTest
@testable import PlayMatch

/// Dismiss-on-save: after tapping Save Profile, the edit sheet closes
/// only when the save succeeded. A failed save stays open so the
/// player can fix the problem and retry.
final class DismissOnSaveTests: XCTestCase {

    func testDismissAfterSaveWithNoError() {
        XCTAssertTrue(ProfileSetupView.shouldDismissAfterSave(error: nil))
    }

    func testDismissAfterSaveWithErrorStaysOpen() {
        XCTAssertFalse(ProfileSetupView.shouldDismissAfterSave(error: "That username is already taken."))
    }
}
