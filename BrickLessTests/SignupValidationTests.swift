import XCTest
import FirebaseAuth
@testable import BrickLess

/// Signup + profile-setup validation and auth error messages:
/// the exact strings a new user sees when something is wrong.
final class SignupValidationTests: XCTestCase {

    // MARK: - Signup

    func testValidSignupPasses() {
        XCTAssertNil(SessionStore.validateSignUp(email: "rj@example.com", username: "rjmallik", password: "password123"))
        XCTAssertNil(SessionStore.validateSignUp(email: "rj@example.com", username: "rjmallik", password: "123456"))
    }

    func testSignupRejectsBadEmailFirst() {
        XCTAssertEqual(SessionStore.validateSignUp(email: "not-an-email", username: "rjmallik", password: "password123"),
                       "Enter a valid email address.")
        // Bad email wins over a bad username: checks run in order.
        XCTAssertEqual(SessionStore.validateSignUp(email: "not-an-email", username: "rj", password: "x"),
                       "Enter a valid email address.")
    }

    func testSignupRejectsBadUsername() {
        XCTAssertEqual(SessionStore.validateSignUp(email: "rj@example.com", username: "rj", password: "password123"),
                       "Username must be 3-20 letters, numbers or underscores.")
    }

    func testSignupRejectsBlockedUsername() {
        XCTAssertEqual(SessionStore.validateSignUp(email: "rj@example.com", username: "shithead", password: "password123"),
                       "That username is not allowed. Pick another one.")
    }

    func testSignupRejectsShortPassword() {
        XCTAssertEqual(SessionStore.validateSignUp(email: "rj@example.com", username: "rjmallik", password: "12345"),
                       "Password must be at least 6 characters.")
    }

    func testSignupCheckOrderUsernameBeforePassword() {
        XCTAssertEqual(SessionStore.validateSignUp(email: "rj@example.com", username: "rj", password: "x"),
                       "Username must be 3-20 letters, numbers or underscores.")
    }

    // MARK: - Profile setup names

    func testValidProfilePasses() {
        XCTAssertNil(SessionStore.validateProfile(displayName: "RJ", username: "rjmallik"))
    }

    func testProfileRejectsEmptyDisplayName() {
        XCTAssertEqual(SessionStore.validateProfile(displayName: "", username: "rjmallik"),
                       "Enter your display name.")
    }

    func testProfileRejectsBadUsername() {
        XCTAssertEqual(SessionStore.validateProfile(displayName: "RJ", username: "rj"),
                       "Username must be 3-20 letters, numbers or underscores.")
    }

    func testProfileRejectsBlockedUsernameOrDisplayName() {
        XCTAssertEqual(SessionStore.validateProfile(displayName: "RJ", username: "shithead"),
                       "That name is not allowed. Pick another one.")
        XCTAssertEqual(SessionStore.validateProfile(displayName: "shithead", username: "rjmallik"),
                       "That name is not allowed. Pick another one.")
    }

    // MARK: - Friendly auth errors

    private func authError(_ code: AuthErrorCode.Code) -> NSError {
        NSError(domain: "FIRAuthErrorDomain", code: code.rawValue, userInfo: nil)
    }

    func testFriendlyErrorMessages() {
        XCTAssertEqual(SessionStore.friendlyError(authError(.invalidEmail)), "That email address does not look right.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.emailAlreadyInUse)), "An account already exists for that email.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.weakPassword)), "Password must be at least 6 characters.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.wrongPassword)), "Incorrect email or password.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.invalidCredential)), "Incorrect email or password.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.userNotFound)), "No account with that email.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.userDisabled)), "That account has been disabled.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.tooManyRequests)), "Too many attempts. Try again later.")
        XCTAssertEqual(SessionStore.friendlyError(authError(.networkError)), "No connection. Check your network and try again.")
    }

    func testFriendlyErrorFallsBackForUnknownCodes() {
        let error = NSError(domain: "FIRAuthErrorDomain", code: 12345, userInfo: nil)
        XCTAssertEqual(SessionStore.friendlyError(error), error.localizedDescription)
    }
}
