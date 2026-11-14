import XCTest
@testable import PlayMatch

/// Remember-me credentials: checking Remember me saves the login so
/// the form is prefilled after sign-out; unchecking deletes it. The
/// decision is tested with an in-memory store — never the real
/// Keychain, and never a SessionStore (it touches Firebase Auth).
final class InMemoryCredentialStore: CredentialStoring {
    private var saved: (email: String, password: String)?

    func savedCredentials() -> (email: String, password: String)? { saved }
    func save(email: String, password: String) { saved = (email, password) }
    func delete() { saved = nil }
}

final class RememberMeCredentialsTests: XCTestCase {

    func testApplyRememberMeTrueSavesAndRoundTrips() {
        let store = InMemoryCredentialStore()
        RememberedLogin.apply(rememberMe: true, email: "rj@example.com",
                              password: "secret123", store: store)
        XCTAssertEqual(store.savedCredentials()?.email, "rj@example.com")
        XCTAssertEqual(store.savedCredentials()?.password, "secret123")
    }

    func testApplyRememberMeFalseDeletesPreviouslySaved() {
        let store = InMemoryCredentialStore()
        RememberedLogin.apply(rememberMe: true, email: "rj@example.com",
                              password: "secret123", store: store)
        XCTAssertNotNil(store.savedCredentials())
        RememberedLogin.apply(rememberMe: false, email: "rj@example.com",
                              password: "secret123", store: store)
        XCTAssertNil(store.savedCredentials())
    }

    func testSavingWithDifferentEmailOverwritesOldOne() {
        let store = InMemoryCredentialStore()
        RememberedLogin.apply(rememberMe: true, email: "first@example.com",
                              password: "first-pass", store: store)
        RememberedLogin.apply(rememberMe: true, email: "second@example.com",
                              password: "second-pass", store: store)
        // One saved login, and it is the latest one.
        XCTAssertEqual(store.savedCredentials()?.email, "second@example.com")
        XCTAssertEqual(store.savedCredentials()?.password, "second-pass")
    }

    func testSavedCredentialsNilWhenNothingSaved() {
        XCTAssertNil(InMemoryCredentialStore().savedCredentials())
    }

    func testApplyTrueTwiceKeepsOnlyLatest() {
        let store = InMemoryCredentialStore()
        RememberedLogin.apply(rememberMe: true, email: "a@example.com",
                              password: "pass-a", store: store)
        RememberedLogin.apply(rememberMe: true, email: "b@example.com",
                              password: "pass-b", store: store)
        XCTAssertEqual(store.savedCredentials()?.email, "b@example.com")
        XCTAssertEqual(store.savedCredentials()?.password, "pass-b")
    }
}
