import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Real auth for BrickLess, backed by Firebase Auth + Firestore.
///
/// Replaces the old demo login (hardcoded user/password, users kept only
/// in memory and lost on restart). Now:
/// - Sign up with email + username + password. Firebase Auth owns the
///   password; Firestore owns the profile and the unique username.
/// - Sign in with email or username + password.
/// - A new account goes through profile setup before reaching Home.
/// - The session survives restarts: Firebase restores the signed-in user
///   and the profile is fetched from Firestore.
///
/// Firebase console setup still needed (once, in the console, not code):
/// enable Email/Password in Authentication > Sign-in method, and create
/// a Firestore database. See firestore.rules in the repo root.
class SessionStore: ObservableObject {
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var loginError: String?
    @Published var profile: UserProfile?
    @Published var needsProfileSetup: Bool = false

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.firebaseUser = user
            self.isLoggedIn = user != nil
            if let user {
                self.fetchProfile(uid: user.uid)
            } else {
                self.profile = nil
                self.needsProfileSetup = false
            }
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // MARK: - Sign up

    /// Creates the Auth account, reserves the username, and writes the
    /// starter profile. The account then still needs profile setup.
    func signUp(email: String, username: String, password: String,
                completion: @escaping (Bool, String?) -> Void) {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let username = username.trimmingCharacters(in: .whitespaces)

        if !UserProfile.isValidEmail(email) {
            completion(false, "Enter a valid email address.")
            return
        }
        if !UserProfile.isValidUsername(username) {
            completion(false, "Username must be 3-20 letters, numbers or underscores.")
            return
        }
        if UserProfile.containsBlockedWord(username) {
            completion(false, "That username is not allowed. Pick another one.")
            return
        }
        if password.count < 6 {
            completion(false, "Password must be at least 6 characters.")
            return
        }

        isLoading = true
        loginError = nil

        checkUsernameAvailable(username) { [weak self] available in
            guard let self else { return }
            guard available else {
                self.isLoading = false
                completion(false, "That username is already taken.")
                return
            }
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                guard let self else { return }
                if let error {
                    self.isLoading = false
                    completion(false, Self.friendlyError(error))
                    return
                }
                guard let user = result?.user else {
                    self.isLoading = false
                    completion(false, "Something went wrong creating your account.")
                    return
                }
                // Reserve the username and write the starter profile together.
                let now = Date()
                let profile = UserProfile(
                    id: user.uid,
                    username: username,
                    usernameLower: username.lowercased(),
                    email: email,
                    displayName: username,
                    position: "Any",
                    skillLevel: "Beginner",
                    city: "",
                    sports: [],
                    profileComplete: false,
                    createdAt: now,
                    updatedAt: now
                )
                let batch = self.db.batch()
                batch.setData(["uid": user.uid, "email": email],
                              forDocument: self.db.collection("usernames").document(username.lowercased()))
                do {
                    try batch.setData(from: profile,
                                      forDocument: self.db.collection("users").document(user.uid))
                } catch {
                    self.isLoading = false
                    completion(false, "Something went wrong saving your profile.")
                    return
                }
                batch.commit { [weak self] error in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        completion(false, Self.friendlyError(error))
                        return
                    }
                    self.profile = profile
                    self.needsProfileSetup = true
                    // Send verification email, best effort; it does not block signup.
                    user.sendEmailVerification(completion: nil)
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - Sign in / out

    /// Accepts an email or a username, plus the password.
    func signIn(emailOrUsername: String, password: String) {
        let input = emailOrUsername.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty, !password.isEmpty else {
            loginError = "Enter your email or username and password."
            return
        }
        isLoading = true
        loginError = nil

        if input.contains("@") {
            signInWithEmail(input.lowercased(), password: password)
        } else {
            // Username sign-in: resolve it to the email first.
            db.collection("usernames").document(input.lowercased()).getDocument { [weak self] snapshot, _ in
                guard let self else { return }
                guard let email = snapshot?.data()?["email"] as? String else {
                    self.isLoading = false
                    self.loginError = "No account with that username."
                    return
                }
                self.signInWithEmail(email, password: password)
            }
        }
    }

    private func signInWithEmail(_ email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self else { return }
            self.isLoading = false
            if let error {
                self.loginError = Self.friendlyError(error)
                return
            }
            self.loginError = nil
            // The auth listener fetches the profile and flips isLoggedIn.
        }
    }

    func sendPasswordReset(email: String, completion: @escaping (String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespaces).lowercased()) { error in
            completion(error.map(Self.friendlyError))
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            loginError = Self.friendlyError(error)
        }
    }

    // MARK: - Delete account (App Store Guideline 5.1.1(v))

    /// Deletes the account entirely, in the app: Firestore profile and
    /// username reservation first, then the Firebase Auth user. Firebase
    /// may require a recent sign-in; in that case the user is told to sign
    /// out and back in, then try again.
    func deleteAccount(completion: @escaping (String?) -> Void) {
        guard let user = firebaseUser else {
            completion("You are not signed in.")
            return
        }
        isLoading = true
        let uid = user.uid
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(uid))
        if let lower = profile?.usernameLower, !lower.isEmpty {
            batch.deleteDocument(db.collection("usernames").document(lower))
        }
        batch.commit { [weak self] _ in
            // Firestore cleanup is best effort; the Auth delete is the point.
            user.delete { [weak self] error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    let nsError = error as NSError
                    // The Firebase version Xcode resolved makes
                    // AuthErrorCode a struct whose cases live on the
                    // nested Code enum, so the raw value is read there.
                    if AuthErrorCode.Code(rawValue: nsError.code) == .requiresRecentLogin {
                        completion("For security, sign out and sign back in, then delete your account again.")
                    } else {
                        completion(Self.friendlyError(error))
                    }
                    return
                }
                self.profile = nil
                self.needsProfileSetup = false
                completion(nil)
            }
        }
    }

    // MARK: - Profile

    func fetchProfile(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self else { return }
            guard let snapshot, snapshot.exists else {
                // Auth user with no profile doc (e.g. created before profiles
                // existed): send them through setup.
                self.profile = nil
                self.needsProfileSetup = true
                return
            }
            do {
                let fetched = try snapshot.data(as: UserProfile.self)
                self.profile = fetched
                // Setup is only done once Save Profile has been tapped,
                // so closing the app mid-setup brings you back to setup.
                self.needsProfileSetup = !fetched.profileComplete
            } catch {
                self.profile = nil
                self.needsProfileSetup = true
            }
        }
    }

    /// Saves profile setup / edits. A username change re-checks availability
    /// and moves the reservation to the new name.
    func saveProfile(displayName: String, username: String, position: String,
                     skillLevel: String, city: String, sports: [String] = [],
                     completion: @escaping (String?) -> Void) {
        guard let user = firebaseUser else {
            completion("You are not signed in.")
            return
        }
        let displayName = displayName.trimmingCharacters(in: .whitespaces)
        let username = username.trimmingCharacters(in: .whitespaces)
        guard !displayName.isEmpty else {
            completion("Enter your display name.")
            return
        }
        guard UserProfile.isValidUsername(username) else {
            completion("Username must be 3-20 letters, numbers or underscores.")
            return
        }
        guard !UserProfile.containsBlockedWord(username),
              !UserProfile.containsBlockedWord(displayName) else {
            completion("That name is not allowed. Pick another one.")
            return
        }

        isLoading = true
        let oldLower = profile?.usernameLower ?? ""
        let newLower = username.lowercased()

        let finish: (String?) -> Void = { [weak self] error in
            self?.isLoading = false
            completion(error)
        }

        func writeProfile() {
            var updated = self.profile ?? UserProfile(
                id: user.uid, username: username, usernameLower: newLower,
                email: user.email ?? "", displayName: displayName,
                position: position, skillLevel: skillLevel, city: city,
                sports: sports,
                profileComplete: true,
                createdAt: Date(), updatedAt: Date())
            updated.username = username
            updated.usernameLower = newLower
            updated.displayName = displayName
            updated.position = position
            updated.skillLevel = skillLevel
            updated.city = city.trimmingCharacters(in: .whitespaces)
            updated.sports = sports
            updated.profileComplete = true
            updated.updatedAt = Date()

            let batch = self.db.batch()
            if !oldLower.isEmpty, oldLower != newLower {
                batch.deleteDocument(self.db.collection("usernames").document(oldLower))
            }
            batch.setData(["uid": user.uid, "email": user.email ?? ""],
                          forDocument: self.db.collection("usernames").document(newLower))
            do {
                try batch.setData(from: updated, forDocument: self.db.collection("users").document(user.uid))
            } catch {
                finish("Something went wrong saving your profile.")
                return
            }
            batch.commit { [weak self] error in
                if error == nil {
                    self?.profile = updated
                    self?.needsProfileSetup = false
                }
                finish(error.map(Self.friendlyError))
            }
        }

        if newLower == oldLower {
            writeProfile()
        } else {
            checkUsernameAvailable(username) { available in
                guard available else {
                    finish("That username is already taken.")
                    return
                }
                writeProfile()
            }
        }
    }

    /// True when no `usernames/{lower}` doc exists.
    func checkUsernameAvailable(_ username: String, completion: @escaping (Bool) -> Void) {
        db.collection("usernames").document(username.lowercased()).getDocument { snapshot, _ in
            completion(snapshot?.exists != true)
        }
    }

    // MARK: - Errors

    static func friendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode.Code(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .invalidEmail: return "That email address does not look right."
        case .emailAlreadyInUse: return "An account already exists for that email."
        case .weakPassword: return "Password must be at least 6 characters."
        case .wrongPassword, .invalidCredential: return "Incorrect email or password."
        case .userNotFound: return "No account with that email."
        case .userDisabled: return "That account has been disabled."
        case .tooManyRequests: return "Too many attempts. Try again later."
        case .networkError: return "No connection. Check your network and try again."
        default: return error.localizedDescription
        }
    }
}
