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

    // MARK: - Validation (pure, unit-tested)

    /// Signup field checks, in the order signUp reports them. Pure:
    /// no Firebase calls, so the unit tests cover the exact messages
    /// a new user sees. Callers pass the already-trimmed email
    /// (lowercased) and username, exactly as signUp prepares them.
    static func validateSignUp(email: String, username: String, password: String) -> String? {
        if !UserProfile.isValidEmail(email) {
            return "Enter a valid email address."
        }
        if !UserProfile.isValidUsername(username) {
            return "Username must be 3-20 letters, numbers or underscores."
        }
        if UserProfile.containsBlockedWord(username) {
            return "That username is not allowed. Pick another one."
        }
        if password.count < 6 {
            return "Password must be at least 6 characters."
        }
        return nil
    }

    /// Profile-setup name checks, in the order saveProfile reports
    /// them. Callers pass the already-trimmed display name and username.
    static func validateProfile(displayName: String, username: String) -> String? {
        if displayName.isEmpty {
            return "Enter your display name."
        }
        if !UserProfile.isValidUsername(username) {
            return "Username must be 3-20 letters, numbers or underscores."
        }
        if UserProfile.containsBlockedWord(username)
            || UserProfile.containsBlockedWord(displayName) {
            return "That name is not allowed. Pick another one."
        }
        return nil
    }

    // MARK: - Sign up

    /// Creates the Auth account, reserves the username, and writes the
    /// starter profile. The account then still needs profile setup.
    func signUp(email: String, username: String, password: String,
                completion: @escaping (Bool, String?) -> Void) {
        let email = email.trimmingCharacters(in: .whitespaces).lowercased()
        let username = username.trimmingCharacters(in: .whitespaces)

        if let error = Self.validateSignUp(email: email, username: username, password: password) {
            completion(false, error)
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

    /// One cleanup query for Delete Account: every doc in `collectionPath`
    /// where `field == value`, or every doc in the collection when `field`
    /// is nil (the blocks subcollection). Pure value type so the unit
    /// tests can pin down exactly what cleanup covers without Firebase.
    struct DeleteAccountQuery: Equatable {
        let collectionPath: String
        let field: String?
        let value: String?
    }

    /// Firestore allows at most 500 writes per batch, so cleanup deletes
    /// are chunked at this size. Query pages use the same size.
    static let deleteAccountBatchLimit = 500

    /// Splits a list into chunks of at most `size` items. Pure, so the
    /// unit tests cover the batch-limit math without Firebase.
    static func chunked<T>(_ items: [T], size: Int) -> [[T]] {
        guard size > 0 else { return [] }
        var chunks: [[T]] = []
        var index = 0
        while index < items.count {
            chunks.append(Array(items[index..<min(index + size, items.count)]))
            index += size
        }
        return chunks
    }

    /// The collections Delete Account cleans up, as query descriptors.
    /// Covers, for the deleting user:
    /// - friendships in either direction (fromUid or toUid)
    /// - bookings they made (bookedBy)
    /// - blocks they created (blocks/{uid}/blocked, every doc)
    /// - reports they filed (reporterUid)
    /// Out of scope on purpose: events they created (needs chat-message
    /// cleanup, a separate fix) and removing them from events they
    /// joined. Nothing here touches other users' data.
    static func deleteAccountCleanupQueries(uid: String) -> [DeleteAccountQuery] {
        [
            DeleteAccountQuery(collectionPath: "friendships", field: "fromUid", value: uid),
            DeleteAccountQuery(collectionPath: "friendships", field: "toUid", value: uid),
            DeleteAccountQuery(collectionPath: "bookings", field: "bookedBy", value: uid),
            DeleteAccountQuery(collectionPath: "blocks/\(uid)/blocked", field: nil, value: nil),
            DeleteAccountQuery(collectionPath: "reports", field: "reporterUid", value: uid),
        ]
    }

    /// Deletes the account entirely, in the app: Firestore profile and
    /// username reservation first, then best-effort cleanup of the user's
    /// friendships, bookings, blocks and reports, then the Firebase Auth
    /// user. Firebase may require a recent sign-in; in that case the user
    /// is told to sign out and back in, then try again.
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
            guard let self else { return }
            self.deleteAccountCleanup(uid: uid) {
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
    }

    /// Best-effort cleanup for Delete Account: fetches every doc matching
    /// `deleteAccountCleanupQueries(uid:)` (paged, so a user with more
    /// than one page of friendships/bookings/blocks/reports is fully
    /// covered), then deletes them in batches of at most
    /// `deleteAccountBatchLimit`. Any failure (query or batch) is
    /// swallowed: cleanup never blocks the Auth delete, and `completion`
    /// always runs exactly once. The `reports` query also needs the
    /// rules to let the reporter read and delete their own reports;
    /// without that rule those docs are silently skipped.
    private func deleteAccountCleanup(uid: String, completion: @escaping () -> Void) {
        let queries = Self.deleteAccountCleanupQueries(uid: uid)
        collectCleanupRefs(queries: queries, index: 0, found: []) { [weak self] refs in
            guard let self else {
                // Store gone mid-cleanup: skip the deletes, but still
                // run completion so the Auth delete is never blocked.
                completion()
                return
            }
            self.deleteRefsInBatches(refs, completion: completion)
        }
    }

    /// Runs each cleanup query in turn, accumulating the document refs.
    /// Refs are deduplicated by path: the two friendships queries can
    /// overlap if a user ever friended themself.
    private func collectCleanupRefs(queries: [DeleteAccountQuery], index: Int,
                                    found: [DocumentReference],
                                    completion: @escaping ([DocumentReference]) -> Void) {
        guard index < queries.count else {
            var seen = Set<String>()
            let deduped = found.filter { seen.insert($0.path).inserted }
            completion(deduped)
            return
        }
        fetchCleanupRefs(for: queries[index], found: found) { [weak self] updated in
            guard let self else {
                completion(updated)
                return
            }
            self.collectCleanupRefs(queries: queries, index: index + 1,
                                    found: updated, completion: completion)
        }
    }

    /// Fetches every doc matching one cleanup query, one page at a time.
    /// A failed page ends that query (best effort) instead of failing
    /// the whole cleanup.
    private func fetchCleanupRefs(for query: DeleteAccountQuery,
                                  after lastDoc: QueryDocumentSnapshot? = nil,
                                  found: [DocumentReference],
                                  completion: @escaping ([DocumentReference]) -> Void) {
        var firestoreQuery: Query = db.collection(query.collectionPath)
        if let field = query.field, let value = query.value {
            firestoreQuery = firestoreQuery.whereField(field, isEqualTo: value)
        }
        firestoreQuery = firestoreQuery.limit(to: Self.deleteAccountBatchLimit)
        if let lastDoc {
            firestoreQuery = firestoreQuery.start(afterDocument: lastDoc)
        }
        firestoreQuery.getDocuments { [weak self] snapshot, _ in
            guard let self, let snapshot else {
                completion(found)
                return
            }
            let updated = found + snapshot.documents.map { $0.reference }
            if snapshot.documents.count < Self.deleteAccountBatchLimit {
                completion(updated)
            } else {
                self.fetchCleanupRefs(for: query, after: snapshot.documents.last,
                                      found: updated, completion: completion)
            }
        }
    }

    /// Deletes refs in batches of at most `deleteAccountBatchLimit`.
    /// A failed batch is swallowed and the rest still run.
    private func deleteRefsInBatches(_ refs: [DocumentReference], completion: @escaping () -> Void) {
        let chunks = Self.chunked(refs, size: Self.deleteAccountBatchLimit)
        deleteRefChunks(chunks, index: 0, completion: completion)
    }

    private func deleteRefChunks(_ chunks: [[DocumentReference]], index: Int,
                                 completion: @escaping () -> Void) {
        guard index < chunks.count else {
            completion()
            return
        }
        let batch = db.batch()
        chunks[index].forEach { batch.deleteDocument($0) }
        batch.commit { [weak self] _ in
            guard let self else {
                completion()
                return
            }
            self.deleteRefChunks(chunks, index: index + 1, completion: completion)
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
                     age: Int? = nil, heightInches: Int? = nil,
                     highestLevel: String = UserProfile.defaultHighestLevel,
                     completion: @escaping (String?) -> Void) {
        guard let user = firebaseUser else {
            completion("You are not signed in.")
            return
        }
        let displayName = displayName.trimmingCharacters(in: .whitespaces)
        let username = username.trimmingCharacters(in: .whitespaces)
        if let error = Self.validateProfile(displayName: displayName, username: username) {
            completion(error)
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
            updated.age = age
            updated.heightInches = heightInches
            updated.highestLevel = highestLevel
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
