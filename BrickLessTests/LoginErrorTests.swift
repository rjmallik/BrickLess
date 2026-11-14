import XCTest
import FirebaseAuth
@testable import PlayMatch

/// Failed sign-in always shows a message: the blank-field message
/// when Login is tapped with an empty field, and a Firebase error
/// message for every auth failure. The exact Firebase strings live
/// in SignupValidationTests; these tests pin the sign-in side: the
/// validation message itself, and that no sign-in failure maps to
/// an empty message (a failed sign-in must never come back silent).
final class LoginErrorTests: XCTestCase {

    func testSignInValidationEmptyEmail() {
        XCTAssertEqual(SessionStore.signInValidationError(email: "", password: "123456"),
                       "Enter your email and password.")
    }

    func testSignInValidationWhitespaceOnlyEmail() {
        XCTAssertEqual(SessionStore.signInValidationError(email: "   ", password: "123456"),
                       "Enter your email and password.")
    }

    func testSignInValidationEmptyPassword() {
        XCTAssertEqual(SessionStore.signInValidationError(email: "qa@brickless.app", password: ""),
                       "Enter your email and password.")
    }

    func testSignInValidationBothEmpty() {
        XCTAssertEqual(SessionStore.signInValidationError(email: "", password: ""),
                       "Enter your email and password.")
    }

    func testSignInValidationValidCredentialsPass() {
        XCTAssertNil(SessionStore.signInValidationError(email: "qa@brickless.app", password: "123456"))
        // Surrounding spaces are trimmed, so they still pass.
        XCTAssertNil(SessionStore.signInValidationError(email: "  qa@brickless.app  ", password: "123456"))
    }

    func testEverySignInFailureHasAMessageToShow() {
        // Every Firebase failure sign-in can hit (wrong password,
        // unknown account, bad email, no connection, too many
        // attempts, disabled account) maps to a non-empty message.
        let codes: [AuthErrorCode.Code] = [
            .wrongPassword, .invalidCredential, .userNotFound,
            .invalidEmail, .networkError, .tooManyRequests, .userDisabled,
        ]
        for code in codes {
            let error = NSError(domain: "FIRAuthErrorDomain", code: code.rawValue, userInfo: nil)
            XCTAssertFalse(SessionStore.friendlyError(error).isEmpty,
                           "No message for \(code)")
        }
    }
}
