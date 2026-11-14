import Foundation
import Combine
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

/// Real auth for PlayMatch, backed by Firebase Auth + Firestore.
///
/// Replaces the old demo login (hardcoded user/password, users kept only
/// in memory and lost on restart). Now:
/// - Sign up with email + username + password. Firebase Auth owns the
///   password; Firestore owns the profile and the unique username.
/// - Sign in with email or username + password.
/// - A new account goes through profile setup before reaching Home.
/// - The session survives restarts only when the user asked to be
///   remembered: Firebase restores the signed-in user, but on launch
///   a restored session without "Remember me" is signed out so the
///   sign-in screen shows first instead of jumping to profile setup.
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

    /// Where Remember-me credentials live (Keychain in the app).
    /// Injectable so tests can swap in an in-memory store.
    private let credentialStore: CredentialStoring

    /// True once the launch-time auth decision has run. Firebase fires
    /// the auth listener once at startup (with the restored user, if
    /// any) and again on every sign-in/sign-out. Only the first fire
    /// is the launch decision; later fires must not sign the user out.
    private var didHandleLaunchAuth = false

    init(credentialStore: CredentialStoring = KeychainCredentialStore()) {
        self.credentialStore = credentialStore
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if !self.didHandleLaunchAuth {
                self.didHandleLaunchAuth = true
                // Launch only: if a session was restored but the user
                // did not ask to be remembered, sign them out so the
                // sign-in screen shows instead of jumping straight to
                // profile setup. A fresh sign-in during the session
                // fires the listener again, but the flag is already
                // set, so it stays signed in for that session; the
                // choice only controls the next launch.
                if Self.launchSessionDecision(restoredUserExists: user != nil,
                                             rememberMe: Self.storedRememberMe()) == .signOutToLogin {
                    self.firebaseUser = nil
                    self.isLoggedIn = false
                    self.profile = nil
                    self.needsProfileSetup = false
                    try? Auth.auth().signOut()
                    return
                }
            }
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

    // MARK: - Remember me (launch)

    /// The UserDefaults key for "Remember me". The LoginView and
    /// RegisterView checkboxes write it via @AppStorage; the launch
    /// decision below reads it, so all three share one stored value.
    static let rememberMeDefaultsKey = "playmatch_remember_me"

    /// The stored "Remember me" choice: false when the user never set
    /// it (UserDefaults.bool returns false for a missing key). Takes
    /// the defaults explicitly so tests can use an isolated suite.
    static func storedRememberMe(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: rememberMeDefaultsKey)
    }

    /// What the first auth-state fire at launch should do with a
    /// restored session.
    enum LaunchSessionDecision: Equatable {
        /// A user was restored and asked to be remembered: stay signed in.
        case keepSignedIn
        /// A user was restored but did not ask to be remembered: sign
        /// them out so the sign-in screen shows.
        case signOutToLogin
        /// No user was restored: the sign-in screen shows.
        case showLogin
    }

    /// The launch decision, pure so it is unit-testable: whether a
    /// restored session stays signed in depends only on whether a user
    /// was restored and whether they asked to be remembered.
    static func launchSessionDecision(restoredUserExists: Bool, rememberMe: Bool) -> LaunchSessionDecision {
        if !restoredUserExists { return .showLogin }
        return rememberMe ? .keepSignedIn : .signOutToLogin
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
                batch.setData(["uid": user.uid],
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

    /// The message shown when sign-in cannot start because a field
    /// is blank. Pure so the unit tests cover the exact message a
    /// failed sign-in shows when Login is tapped with an empty field.
    static func signInValidationError(email: String, password: String) -> String? {
        if email.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty {
            return "Enter your email and password."
        }
        return nil
    }

    /// The Login button's label: it turns into an in-progress label
    /// the moment a sign-in starts, so the tap visibly lands. Pure
    /// so the unit tests pin the exact strings.
    static func loginButtonTitle(isLoading: Bool) -> String {
        isLoading ? "Signing in…" : "Login"
    }

    /// Whether the Login button ignores taps: while a sign-in is in
    /// flight, so extra taps cannot start a duplicate request. Pure
    /// so the unit tests pin the rule.
    static func loginButtonDisabled(isLoading: Bool) -> Bool {
        isLoading
    }

    /// Accepts an email or a username, plus the password.
    /// `completion` reports whether the sign-in succeeded, so the
    /// caller can apply the Remember-me choice only on success.
    /// Every failure sets loginError, so the login screen always has
    /// a message to show: a blank field, a Firebase error, or a
    /// duplicate tap while one is already in flight (which reports
    /// failure without starting a second request or clearing the
    /// in-flight attempt's error).
    func signIn(email: String, password: String, completion: ((Bool) -> Void)? = nil) {
        if let error = Self.signInValidationError(email: email, password: password) {
            loginError = error
            completion?(false)
            return
        }
        // Extra taps while a sign-in is already in flight are
        // ignored: on the login screen isLoading is only ever true
        // for a sign-in, so this never blocks a fresh attempt.
        guard !isLoading else {
            completion?(false)
            return
        }
        isLoading = true
        loginError = nil

        // Email-only sign-in. Username sign-in was removed: resolving a
        // username to an email needs a public username-to-email mapping,
        // which would expose every user's email to anyone who looks a
        // name up. The email lives in Firebase Auth only.
        signInWithEmail(email.trimmingCharacters(in: .whitespaces).lowercased(), password: password, completion: completion)
    }

    /// The login saved by Remember me, if any (Keychain). The login
    /// screen prefills its email and password fields from this.
    func savedLoginCredentials() -> (email: String, password: String)? {
        credentialStore.savedCredentials()
    }

    /// Apply the Remember-me choice after a successful sign-in:
    /// checked -> save the credentials to the Keychain; unchecked ->
    /// delete any saved ones. Signing out never calls this, so saved
    /// credentials survive sign-out and prefill the next login.
    func applyRememberMe(email: String, password: String) {
        RememberedLogin.apply(rememberMe: Self.storedRememberMe(),
                              email: email, password: password,
                              store: credentialStore)
    }

    private func signInWithEmail(_ email: String, password: String, completion: ((Bool) -> Void)? = nil) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self else { return }
            // Deliver the result on the main queue: the error message
            // and the spinner going away are @Published writes, and a
            // callback that lands off the main thread can leave the
            // login screen showing neither the error nor the button.
            DispatchQueue.main.async {
                self.isLoading = false
                if let error {
                    self.loginError = Self.friendlyError(error)
                    completion?(false)
                    return
                }
                self.loginError = nil
                completion?(true)
                // The auth listener fetches the profile and flips isLoggedIn.
            }
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
    /// Events are not in this list: they need special handling (a
    /// created event's chat must be deleted before the event doc, and
    /// a joined event only loses the user from playerUids), so they
    /// go through `deleteAccountEventQueries(uid:)` instead. Nothing
    /// here touches other users' data.
    static func deleteAccountCleanupQueries(uid: String) -> [DeleteAccountQuery] {
        [
            DeleteAccountQuery(collectionPath: "friendships", field: "fromUid", value: uid),
            DeleteAccountQuery(collectionPath: "friendships", field: "toUid", value: uid),
            DeleteAccountQuery(collectionPath: "bookings", field: "bookedBy", value: uid),
            DeleteAccountQuery(collectionPath: "blocks/\(uid)/blocked", field: nil, value: nil),
            DeleteAccountQuery(collectionPath: "reports", field: "reporterUid", value: uid),
        ]
    }

    /// One of the events queries Delete Account runs. Unlike the
    /// plain cleanup queries above (always `isEqualTo`), the joined
    /// query is an `arrayContains` on playerUids.
    struct DeleteAccountEventQuery: Equatable {
        enum Operator: Equatable {
            case equal
            case arrayContains
        }
        let collectionPath: String
        let field: String
        let value: String
        let op: Operator
    }

    /// The events Delete Account touches, as query descriptors:
    /// - events the user created (creatorUid == uid): deleted
    ///   entirely, chat messages first, then the event doc. A created
    ///   game has no host once its creator is gone, and there is no
    ///   ownership-transfer concept, so the game goes away rather than
    ///   stranding its players in a hostless chat.
    /// - events the user joined (playerUids arrayContains uid): the
    ///   user is removed from playerUids and the game stays for the
    ///   other players.
    static func deleteAccountEventQueries(uid: String) -> [DeleteAccountEventQuery] {
        [
            DeleteAccountEventQuery(collectionPath: "events", field: "creatorUid", value: uid, op: .equal),
            DeleteAccountEventQuery(collectionPath: "events", field: "playerUids", value: uid, op: .arrayContains),
        ]
    }

    /// From the events a user joined (event id -> creatorUid), the
    /// ones to remove them from: everything except events they
    /// created. Created events are deleted outright by the
    /// created-events step, so if one still shows up here (its delete
    /// failed), it is left intact rather than stripping its creator
    /// from the player list. Sorted, so the order is deterministic.
    static func joinedEventsToLeave(_ events: [String: String], uid: String) -> [String] {
        events.filter { $0.value != uid }.map { $0.key }.sorted()
    }

    /// Deletes the account entirely, in the app: Firestore profile and
    /// username reservation first, then best-effort cleanup of the user's
    /// friendships, bookings, blocks, reports, created events (with
    /// their chats), and removal from events they joined, then the
    /// Firebase Auth user. Firebase may require a recent sign-in; in
    /// that case the user is told to sign out and back in, then try again.
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
            self.deleteAccountCleanup(uid: uid) { [weak self] in
                guard let self else { return }
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
    /// covered), deletes them in batches of at most
    /// `deleteAccountBatchLimit`, then deletes events the user created
    /// (chat first, then the event doc) and removes them from events
    /// they joined. Any failure (query or batch) is swallowed: cleanup
    /// never blocks the Auth delete, and `completion` always runs
    /// exactly once. The `reports` query also needs the rules to let
    /// the reporter read and delete their own reports; without that
    /// rule those docs are silently skipped. The events steps need no
    /// extra rules: message deletes are creator-only while the parent
    /// event exists, event deletes are creator-only, and removing
    /// exactly the caller from playerUids is the leave branch the
    /// hardened rules already allow.
    private func deleteAccountCleanup(uid: String, completion: @escaping () -> Void) {
        let queries = Self.deleteAccountCleanupQueries(uid: uid)
        collectCleanupRefs(queries: queries, index: 0, found: []) { [weak self] refs in
            guard let self else {
                // Store gone mid-cleanup: skip the deletes, but still
                // run completion so the Auth delete is never blocked.
                completion()
                return
            }
            self.deleteRefsInBatches(refs) { [weak self] in
                guard let self else {
                    completion()
                    return
                }
                self.deleteAccountCreatedEvents(uid: uid) { [weak self] in
                    guard let self else {
                        completion()
                        return
                    }
                    self.removeFromJoinedEvents(uid: uid, completion: completion)
                }
            }
        }
    }

    /// Deletes every event the user created, chat first then the event
    /// doc — the same order as EventStore.deleteEvent, because the
    /// messages rule only lets the creator delete while the parent
    /// event still exists. Best effort: if a chat cannot be fully
    /// deleted, that game is left intact (a failed message batch
    /// stops that event's delete, same fail-safe as deleteEvent) and
    /// the rest still run. Completion always runs exactly once.
    private func deleteAccountCreatedEvents(uid: String, completion: @escaping () -> Void) {
        fetchCreatedEventIds(uid: uid) { [weak self] ids in
            guard let self else {
                completion()
                return
            }
            self.deleteCreatedEvents(ids, index: 0, completion: completion)
        }
    }

    /// Fetches the ids of every event whose creatorUid is `uid`, one
    /// page at a time. A failed page ends the fetch (best effort)
    /// instead of failing the whole cleanup.
    private func fetchCreatedEventIds(uid: String,
                                      after lastDoc: QueryDocumentSnapshot? = nil,
                                      found: [String] = [],
                                      completion: @escaping ([String]) -> Void) {
        var query: Query = db.collection("events")
            .whereField("creatorUid", isEqualTo: uid)
            .limit(to: Self.deleteAccountBatchLimit)
        if let lastDoc {
            query = query.start(afterDocument: lastDoc)
        }
        query.getDocuments { [weak self] snapshot, _ in
            guard let self, let snapshot else {
                completion(found)
                return
            }
            let updated = found + snapshot.documents.map { $0.documentID }
            if snapshot.documents.count < Self.deleteAccountBatchLimit {
                completion(updated)
            } else {
                self.fetchCreatedEventIds(uid: uid, after: snapshot.documents.last,
                                          found: updated, completion: completion)
            }
        }
    }

    /// Deletes created events one at a time, messages first via the
    /// shared EventStore helper, then the event doc.
    private func deleteCreatedEvents(_ ids: [String], index: Int, completion: @escaping () -> Void) {
        guard index < ids.count else {
            completion()
            return
        }
        let eventId = ids[index]
        EventStore.deleteAllMessages(db: db, eventId: eventId) { [weak self] error in
            guard let self else {
                completion()
                return
            }
            if error != nil {
                // Chat could not be fully deleted: leave this game
                // intact rather than orphaning its messages.
                self.deleteCreatedEvents(ids, index: index + 1, completion: completion)
                return
            }
            self.db.collection("events").document(eventId).delete { [weak self] _ in
                guard let self else {
                    completion()
                    return
                }
                self.deleteCreatedEvents(ids, index: index + 1, completion: completion)
            }
        }
    }

    /// Removes the user from every event they joined that someone else
    /// created. Runs after the created events are deleted, so their
    /// own games never appear here; `joinedEventsToLeave` is a second
    /// line of defence for a created event whose delete failed. Each
    /// leave is the same arrayRemove the Leave button sends, so the
    /// hardened rules accept it (only playerUids changes, exactly the
    /// caller is removed). Best effort; completion always runs once.
    private func removeFromJoinedEvents(uid: String, completion: @escaping () -> Void) {
        fetchJoinedEvents(uid: uid) { [weak self] events in
            guard let self else {
                completion()
                return
            }
            let toLeave = Self.joinedEventsToLeave(events, uid: uid)
            self.leaveEventsInBatches(toLeave, uid: uid, completion: completion)
        }
    }

    /// Fetches every event the user joined, as event id -> creatorUid,
    /// one page at a time. A failed page ends the fetch (best effort).
    private func fetchJoinedEvents(uid: String,
                                   after lastDoc: QueryDocumentSnapshot? = nil,
                                   found: [String: String] = [:],
                                   completion: @escaping ([String: String]) -> Void) {
        var query: Query = db.collection("events")
            .whereField("playerUids", arrayContains: uid)
            .limit(to: Self.deleteAccountBatchLimit)
        if let lastDoc {
            query = query.start(afterDocument: lastDoc)
        }
        query.getDocuments { [weak self] snapshot, _ in
            guard let self, let snapshot else {
                completion(found)
                return
            }
            var updated = found
            for doc in snapshot.documents {
                updated[doc.documentID] = doc.data()["creatorUid"] as? String ?? ""
            }
            if snapshot.documents.count < Self.deleteAccountBatchLimit {
                completion(updated)
            } else {
                self.fetchJoinedEvents(uid: uid, after: snapshot.documents.last,
                                       found: updated, completion: completion)
            }
        }
    }

    /// Removes `uid` from playerUids of the given events, in batches of
    /// at most `deleteAccountBatchLimit` updates per commit. A failed
    /// batch is swallowed and the rest still run.
    private func leaveEventsInBatches(_ ids: [String], uid: String, completion: @escaping () -> Void) {
        let chunks = Self.chunked(ids, size: Self.deleteAccountBatchLimit)
        leaveEventChunks(chunks, uid: uid, index: 0, completion: completion)
    }

    private func leaveEventChunks(_ chunks: [[String]], uid: String, index: Int,
                                  completion: @escaping () -> Void) {
        guard index < chunks.count else {
            completion()
            return
        }
        let batch = db.batch()
        chunks[index].forEach { eventId in
            batch.updateData(["playerUids": FieldValue.arrayRemove([uid])],
                             forDocument: db.collection("events").document(eventId))
        }
        batch.commit { [weak self] _ in
            guard let self else {
                completion()
                return
            }
            self.leaveEventChunks(chunks, uid: uid, index: index + 1, completion: completion)
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
    /// Saves the profile. Per-sport detail comes in as `sportProfiles`
    /// (one entry per opted-in sport); the top-level `position` and
    /// `skillLevel` are derived from the primary sport, and the top-level
    /// `highestLevel` is the max across sports, so the Players level
    /// filter keeps working on a single field. `photoURL` is the full
    /// new photo URL (nil when the photo was removed); the caller
    /// always passes it, so an unchanged photo is passed through.
    func saveProfile(displayName: String, username: String,
                     city: String, sports: [String] = [],
                     sportProfiles: [SportProfile] = [],
                     age: Int? = nil, heightInches: Int? = nil,
                     photoURL: String? = nil,
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

        // Primary sport (first opted-in sport, in allSports order) carries
        // the list-row position and skill level; "Any" when nothing picked.
        let primary = UserProfile.primarySportProfile(from: sportProfiles)
        let position = primary?.positions.first ?? "Any"
        let skillLevel = primary?.skillLevel ?? "Beginner"
        let highestLevel = UserProfile.overallHighestLevel(from: sportProfiles)

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
                displayName: displayName,
                position: position, skillLevel: skillLevel, city: city,
                sports: sports, sportProfiles: sportProfiles,
                profileComplete: true,
                createdAt: Date(), updatedAt: Date())
            updated.username = username
            updated.usernameLower = newLower
            updated.displayName = displayName
            updated.position = position
            updated.skillLevel = skillLevel
            updated.city = city.trimmingCharacters(in: .whitespaces)
            updated.sports = sports
            updated.sportProfiles = sportProfiles
            updated.age = age
            updated.heightInches = heightInches
            updated.highestLevel = highestLevel
            updated.photoURL = photoURL
            updated.profileComplete = true
            updated.updatedAt = Date()

            let batch = self.db.batch()
            if !oldLower.isEmpty, oldLower != newLower {
                batch.deleteDocument(self.db.collection("usernames").document(oldLower))
            }
            batch.setData(["uid": user.uid],
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

    // MARK: - Profile photo

    /// Uploads a profile photo to Storage at
    /// `UserProfile.photoStoragePath(for: uid)` (one fixed path per
    /// user, so a new photo overwrites the old one), after resizing
    /// to at most `profilePhotoMaxDimension` and JPEG-compressing at
    /// `profilePhotoJPEGQuality`, so photos stay small on the free
    /// Spark plan (5 GB of Storage). Calls completion with the
    /// download URL on success, or an error. Sets isLoading while
    /// the upload runs, so the Save button shows a spinner.
    func uploadProfilePhoto(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = firebaseUser?.uid else {
            completion(.failure(Self.photoError("You are not signed in.")))
            return
        }
        guard let data = Self.photoJPEGData(for: image) else {
            completion(.failure(Self.photoError("That photo could not be read.")))
            return
        }
        isLoading = true
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let ref = Storage.storage().reference().child(UserProfile.photoStoragePath(for: uid))
        ref.putData(data, metadata: metadata) { [weak self] _, error in
            if let error {
                self?.isLoading = false
                completion(.failure(error))
                return
            }
            ref.downloadURL { [weak self] url, error in
                self?.isLoading = false
                if let url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(error ?? Self.photoError("Could not get the photo link.")))
                }
            }
        }
    }

    /// Deletes the user's profile photo from Storage. Best effort,
    /// used when the user removes their photo; the profile save
    /// itself clears the URL. A failure is ignored: an orphaned
    /// file is harmless on the free tier.
    func deleteProfilePhoto() {
        guard let uid = firebaseUser?.uid else { return }
        Storage.storage().reference().child(UserProfile.photoStoragePath(for: uid)).delete { _ in }
    }

    /// Resized + JPEG-compressed data for a profile photo, or nil
    /// when the image cannot be encoded. Static so the unit tests
    /// can cover the encoding without Firebase.
    static func photoJPEGData(for image: UIImage) -> Data? {
        let target = UserProfile.scaledPhotoSize(for: image.size,
                                                 maxDimension: UserProfile.profilePhotoMaxDimension)
        let resized: UIImage
        if target == image.size {
            resized = image
        } else {
            // Scale 1: the rendered image is `target` pixels, not
            // `target` points times the screen scale, so the cap is
            // really 1024 pixels on the longest side.
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: target, format: format)
            resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        }
        return resized.jpegData(compressionQuality: UserProfile.profilePhotoJPEGQuality)
    }

    private static func photoError(_ message: String) -> Error {
        NSError(domain: "PlayMatch", code: 0,
                userInfo: [NSLocalizedDescriptionKey: message])
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
        case .wrongPassword, .invalidCredential: return "Username or password not recognized."
        case .userNotFound: return "Username or password not recognized."
        case .userDisabled: return "That account has been disabled."
        case .tooManyRequests: return "Too many attempts. Try again later."
        case .networkError: return "No connection. Check your network and try again."
        default: return error.localizedDescription
        }
    }
}
