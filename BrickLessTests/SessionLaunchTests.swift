import XCTest
@testable import PlayMatch

/// "Remember me" launch flow: the pure launch decision and the stored
/// default. The decision only runs on the first auth-state fire at
/// launch; a fresh sign-in during the session is never signed out by it.
final class SessionLaunchTests: XCTestCase {

    func testLaunchDecisionRestoredAndRememberedKeepsSignedIn() {
        XCTAssertEqual(
            SessionStore.launchSessionDecision(restoredUserExists: true, rememberMe: true),
            .keepSignedIn)
    }

    func testLaunchDecisionRestoredAndNotRememberedSignsOut() {
        XCTAssertEqual(
            SessionStore.launchSessionDecision(restoredUserExists: true, rememberMe: false),
            .signOutToLogin)
    }

    func testLaunchDecisionNoRestoredUserShowsLogin() {
        XCTAssertEqual(
            SessionStore.launchSessionDecision(restoredUserExists: false, rememberMe: true),
            .showLogin)
        XCTAssertEqual(
            SessionStore.launchSessionDecision(restoredUserExists: false, rememberMe: false),
            .showLogin)
    }

    func testRememberMeDefaultsToFalse() throws {
        // A fresh UserDefaults suite has no value for the key, so the
        // stored choice reads as false (not remembered).
        let suite = "playmatch-test-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        XCTAssertFalse(SessionStore.storedRememberMe(defaults: defaults))
        defaults.removePersistentDomain(forName: suite)
    }

    func testStoredRememberMeReadsTheKey() throws {
        let suite = "playmatch-test-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defaults.set(true, forKey: SessionStore.rememberMeDefaultsKey)
        XCTAssertTrue(SessionStore.storedRememberMe(defaults: defaults))
        defaults.set(false, forKey: SessionStore.rememberMeDefaultsKey)
        XCTAssertFalse(SessionStore.storedRememberMe(defaults: defaults))
        defaults.removePersistentDomain(forName: suite)
    }
}
