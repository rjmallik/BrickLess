import Foundation
import Security

/// Remember-me credentials: the email + password saved when the
/// player checks "Remember me" at sign-in, so the login form is
/// prefilled after sign-out. Signing out ends the Firebase session
/// but must NOT clear these — that is the point: the player just
/// taps Login next time instead of retyping both fields.
///
/// The password lives in the iOS Keychain (one generic-password
/// item for this app), NEVER in UserDefaults or any plaintext store.
/// The storage sits behind a small protocol so the behaviour is
/// unit-tested with an in-memory store instead of the real Keychain.
protocol CredentialStoring {
    /// The saved login, if any.
    func savedCredentials() -> (email: String, password: String)?
    /// Save (or overwrite) the login for one account. Signing in
    /// with a different account while Remember me is checked
    /// replaces the saved one.
    func save(email: String, password: String)
    /// Delete any saved login.
    func delete()
}

/// Keychain-backed credential store: one generic-password item,
/// service "com.playmatch.saved-login", account = the email,
/// password = the password data.
final class KeychainCredentialStore: CredentialStoring {
    private let service = "com.playmatch.saved-login"

    func savedCredentials() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let fields = item as? [String: Any],
              let email = fields[kSecAttrAccount as String] as? String,
              let data = fields[kSecValueData as String] as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        return (email, password)
    }

    func save(email: String, password: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        let attributes: [String: Any] = [
            kSecAttrAccount as String: email,
            kSecValueData as String: Data(password.utf8),
        ]
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// The Remember-me decision, applied after a successful sign-in:
/// checked -> save the credentials; unchecked -> delete any saved
/// ones. Pure, so the unit tests pin it down with an in-memory
/// store instead of the real Keychain.
enum RememberedLogin {
    static func apply(rememberMe: Bool, email: String, password: String, store: CredentialStoring) {
        if rememberMe {
            store.save(email: email, password: password)
        } else {
            store.delete()
        }
    }
}
