import XCTest
@testable import PlayMatch

/// Login responsiveness: the button turns into an in-progress label
/// the moment a sign-in starts and ignores taps until it finishes,
/// so the spinner shows immediately and extra taps cannot start a
/// duplicate sign-in request.
final class LoginLoadingTests: XCTestCase {

    func testLoginButtonTitleIsLoginWhenIdle() {
        XCTAssertEqual(SessionStore.loginButtonTitle(isLoading: false), "Login")
    }

    func testLoginButtonTitleIsSigningInWhileLoading() {
        XCTAssertEqual(SessionStore.loginButtonTitle(isLoading: true), "Signing in…")
    }

    func testLoginButtonEnabledWhenIdle() {
        XCTAssertFalse(SessionStore.loginButtonDisabled(isLoading: false))
    }

    func testLoginButtonDisabledWhileLoading() {
        XCTAssertTrue(SessionStore.loginButtonDisabled(isLoading: true))
    }
}
