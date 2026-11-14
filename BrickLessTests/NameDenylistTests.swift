import XCTest
@testable import PlayMatch

/// Display-name denylist (Guideline 1.2): blocked words are caught
/// as substrings, clean names pass.
final class NameDenylistTests: XCTestCase {

    func testBlockedWordsCaught() {
        XCTAssertTrue(UserProfile.containsBlockedWord("shithead"))
        XCTAssertTrue(UserProfile.containsBlockedWord("SHIT"))
        XCTAssertTrue(UserProfile.containsBlockedWord("Dickinson")) // substring match
        XCTAssertTrue(UserProfile.containsBlockedWord("my fuck team"))
    }

    func testCleanNamesPassDenylist() {
        XCTAssertFalse(UserProfile.containsBlockedWord("rjmallik"))
        XCTAssertFalse(UserProfile.containsBlockedWord("Ballers"))
        XCTAssertFalse(UserProfile.containsBlockedWord("classy"))
    }
}
