import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Friend requests and friendships, stored in Firestore.
///
/// `friendships/{id}`: { fromUid, fromUsername, toUid, toUsername,
/// status: "pending" | "accepted" | "declined", createdAt }.
/// "My Guys" is the accepted-friends list. There is no separate friends
/// collection: a friendship is one doc, read from either side.
struct Friendship: Codable, Identifiable {
    @DocumentID var id: String?
    var fromUid: String
    var fromUsername: String
    var toUid: String
    var toUsername: String
    var status: String // pending, accepted, declined
    var createdAt: Date
}

class FriendsStore: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var incomingRequests: [Friendship] = []
    @Published var outgoingRequests: [Friendship] = []
    @Published var searchResults: [UserProfile] = []
    @Published var blockedUids: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    var uid: String? { Auth.auth().currentUser?.uid }

    deinit { listeners.forEach { $0.remove() } }

    /// Live lists for the signed-in user: friends + pending requests.
    func startListening() {
        guard let uid else { return }
        listeners.forEach { $0.remove() }
        listeners = []

        listeners.append(
            db.collection("friendships")
                .whereField("toUid", isEqualTo: uid)
                .whereField("status", isEqualTo: "pending")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.incomingRequests = snapshot?.documents.compactMap {
                        try? $0.data(as: Friendship.self)
                    } ?? []
                }
        )
        listeners.append(
            db.collection("friendships")
                .whereField("fromUid", isEqualTo: uid)
                .whereField("status", isEqualTo: "pending")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.outgoingRequests = snapshot?.documents.compactMap {
                        try? $0.data(as: Friendship.self)
                    } ?? []
                }
        )
        // Accepted friendships, either direction, then resolve to profiles.
        listeners.append(
            db.collection("friendships")
                .whereField("fromUid", isEqualTo: uid)
                .whereField("status", isEqualTo: "accepted")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.resolveFriends(from: snapshot, myUid: uid, otherKey: "toUid")
                }
        )
        listeners.append(
            db.collection("friendships")
                .whereField("toUid", isEqualTo: uid)
                .whereField("status", isEqualTo: "accepted")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.resolveFriends(from: snapshot, myUid: uid, otherKey: "fromUid")
                }
        )
        // Blocked users: hidden from search and friends everywhere below.
        listeners.append(
            db.collection("blocks").document(uid).collection("blocked")
                .addSnapshotListener { [weak self] snapshot, _ in
                    self?.blockedUids = Set(snapshot?.documents.map { $0.documentID } ?? [])
                    self?.friends.removeAll { self?.blockedUids.contains($0.id ?? "") ?? false }
                    self?.searchResults.removeAll { self?.blockedUids.contains($0.id ?? "") ?? false }
                }
        )
    }

    // MARK: - Block and report (App Store Guideline 1.2)

    /// Blocks a player: they disappear from search and friends, and the
    /// block is stored server-side so it survives reinstalls.
    func blockUser(_ profile: UserProfile) {
        guard let uid, let otherUid = profile.id else { return }
        db.collection("blocks").document(uid).collection("blocked")
            .document(otherUid).setData(["blockedUid": otherUid, "createdAt": Date()])
        removeFriend(profile)
        friends.removeAll { $0.id == otherUid }
        searchResults.removeAll { $0.id == otherUid }
    }

    /// Reports a player. Reports are reviewed in the Firebase console;
    /// the app never lists them, so a reported user cannot tell.
    func reportUser(_ profile: UserProfile, reason: String) {
        guard let uid, let otherUid = profile.id else { return }
        let data: [String: Any] = [
            "reporterUid": uid,
            "reportedUid": otherUid,
            "reportedUsername": profile.username,
            "reason": reason,
            "createdAt": Timestamp(date: Date()),
        ]
        db.collection("reports").addDocument(data: data)
    }

    private var friendUids: Set<String> = []

    /// Normalizes a username search query: trimmed and lowercased.
    /// Returns nil when it is too short to search (under 2 chars).
    static func normalizedSearchQuery(_ query: String) -> String? {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.count >= 2 ? q : nil
    }

    /// Search hits with the signed-in user and blocked users removed.
    static func filterSearchResults(_ profiles: [UserProfile], myUid: String, blockedUids: Set<String>) -> [UserProfile] {
        profiles.filter { $0.id != myUid && !blockedUids.contains($0.id ?? "") }
    }

    private func resolveFriends(from snapshot: QuerySnapshot?, myUid: String, otherKey: String) {
        let uids = Set(snapshot?.documents.compactMap { $0.data()[otherKey] as? String } ?? [])
        friendUids.formUnion(uids)
        guard !uids.isEmpty else { return }
        // Firestore `in` takes up to 30 uids; fine for a friends list page.
        db.collection("users").whereField(FieldPath.documentID(), in: Array(uids).prefix(30).map { $0 as String })
            .getDocuments { [weak self] snapshot, _ in
                let profiles = snapshot?.documents.compactMap { try? $0.data(as: UserProfile.self) } ?? []
                self?.friends = Array(
                    Dictionary(grouping: (self?.friends ?? []) + profiles, by: { $0.id ?? "" })
                        .values.compactMap { $0.first }
                ).sorted { $0.usernameLower < $1.usernameLower }
            }
    }

    /// Prefix search by username, e.g. "rj" finds "rjhoops".
    func searchUsers(query: String) {
        guard let q = Self.normalizedSearchQuery(query), let uid else {
            searchResults = []
            return
        }
        isLoading = true
        db.collection("users")
            .order(by: "usernameLower")
            .start(at: [q])
            .end(at: [q + "\u{f8ff}"])
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = SessionStore.friendlyError(error)
                    return
                }
                self.searchResults = Self.filterSearchResults(
                    snapshot?.documents.compactMap {
                        try? $0.data(as: UserProfile.self)
                    } ?? [],
                    myUid: uid, blockedUids: self.blockedUids)
            }
    }

    func sendRequest(to profile: UserProfile, fromUsername: String) {
        guard let uid, let toUid = profile.id else { return }
        let request = Friendship(fromUid: uid, fromUsername: fromUsername,
                                 toUid: toUid, toUsername: profile.username,
                                 status: "pending", createdAt: Date())
        do {
            _ = try db.collection("friendships").addDocument(from: request)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respond(to request: Friendship, accept: Bool) {
        guard let id = request.id else { return }
        db.collection("friendships").document(id)
            .updateData(["status": accept ? "accepted" : "declined"])
    }

    func removeFriend(_ profile: UserProfile) {
        guard let uid, let otherUid = profile.id else { return }
        db.collection("friendships")
            .whereField("fromUid", in: [uid, otherUid])
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { [weak self] snapshot, _ in
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    let isPair = (data["fromUid"] as? String == uid && data["toUid"] as? String == otherUid)
                        || (data["fromUid"] as? String == otherUid && data["toUid"] as? String == uid)
                    if isPair {
                        self?.db.collection("friendships").document(doc.documentID).delete()
                    }
                }
                self?.friends.removeAll { $0.id == otherUid }
            }
    }
}
