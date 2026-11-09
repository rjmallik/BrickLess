import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Browse and discover players, not just people you already know.
///
/// Browse is paginated: 20 profiles at a time, ordered by `usernameLower`,
/// paging with `start(afterDocument:)`. Search reuses the username-prefix
/// pattern from FriendsStore. Level and city filters are applied
/// client-side to the players loaded so far (v1), so no query here needs
/// a composite index: every query is a single-field order/range on
/// `usernameLower`.
class PlayersStore: ObservableObject {
    @Published var players: [UserProfile] = []
    @Published var searchResults: [UserProfile] = []
    @Published var searchText = ""
    @Published var levelFilter = "All"
    @Published var cityFilter = ""
    @Published var blockedUids: Set<String> = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20

    var uid: String? { Auth.auth().currentUser?.uid }

    /// Highest level played, in ascending order. Single source of truth
    /// is UserProfile.highestLevels — these strings must match what
    /// profile setup stores, or the level filter will never match.
    static let levels = UserProfile.highestLevels

    var isSearching: Bool {
        searchText.trimmingCharacters(in: .whitespaces).count >= 2
    }

    /// Players to show: search results while searching, otherwise the
    /// browsed pages, both with the level/city filters applied.
    var visiblePlayers: [UserProfile] {
        let base = isSearching ? searchResults : players
        return base.filter { profile in
            if levelFilter != "All", profile.highestLevel != levelFilter { return false }
            let city = cityFilter.trimmingCharacters(in: .whitespaces)
            if !city.isEmpty, !profile.city.localizedCaseInsensitiveContains(city) { return false }
            return true
        }
    }

    /// First page (or reload). Blocked users are fetched first so they
    /// never appear in the results.
    func refresh() {
        players = []
        searchResults = []
        lastDocument = nil
        hasMore = true
        fetchBlockedUids { [weak self] in
            guard let self else { return }
            if self.isSearching { self.searchUsers() } else { self.loadNextPage() }
        }
    }

    /// Reload the blocked list and drop blocked players from the local
    /// lists, without resetting pagination. Called when returning from a
    /// detail view, where the user may have blocked someone.
    func refreshBlockedUids() {
        fetchBlockedUids { [weak self] in
            guard let self else { return }
            self.players.removeAll { self.blockedUids.contains($0.id ?? "") }
            self.searchResults.removeAll { self.blockedUids.contains($0.id ?? "") }
        }
    }

    private func fetchBlockedUids(completion: @escaping () -> Void) {
        guard let uid else { completion(); return }
        db.collection("blocks").document(uid).collection("blocked")
            .getDocuments { [weak self] snapshot, _ in
                self?.blockedUids = Set(snapshot?.documents.map { $0.documentID } ?? [])
                completion()
            }
    }

    /// Next browse page. No-op while searching, while loading, or when
    /// the last page came back short.
    func loadNextPage() {
        guard !isSearching, !isLoading, hasMore else { return }
        isLoading = true
        var query: Query = db.collection("users")
            .order(by: "usernameLower")
            .limit(to: pageSize)
        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        query.getDocuments { [weak self] snapshot, error in
            guard let self else { return }
            self.isLoading = false
            if let error {
                self.errorMessage = SessionStore.friendlyError(error)
                return
            }
            let docs = snapshot?.documents ?? []
            self.lastDocument = docs.last
            self.hasMore = docs.count == self.pageSize
            let profiles = docs.compactMap { try? $0.data(as: UserProfile.self) }
                .filter { $0.id != self.uid && !self.blockedUids.contains($0.id ?? "") }
            self.players.append(contentsOf: profiles)
        }
    }

    /// Username prefix search, same pattern as FriendsStore.searchUsers.
    func searchUsers() {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2, let uid else {
            searchResults = []
            if players.isEmpty { loadNextPage() }
            return
        }
        isLoading = true
        db.collection("users")
            .order(by: "usernameLower")
            .start(at: [q])
            .end(at: [q + "\u{f8ff}"])
            .limit(to: pageSize)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = SessionStore.friendlyError(error)
                    return
                }
                self.searchResults = (snapshot?.documents.compactMap {
                    try? $0.data(as: UserProfile.self)
                } ?? []).filter { $0.id != uid && !self.blockedUids.contains($0.id ?? "") }
            }
    }

    /// "6'2\"" from 74 inches. Nil when height is not set.
    static func heightString(inches: Int?) -> String? {
        guard let inches else { return nil }
        return "\(inches / 12)'\(inches % 12)\""
    }

    /// One-line summary of the stats a player chose to share, e.g.
    /// "24 · 6'2\" · College · Seattle". Only present values are shown.
    static func statLine(for profile: UserProfile) -> String {
        var parts: [String] = []
        if let age = profile.age { parts.append("\(age)") }
        if let height = heightString(inches: profile.heightInches) { parts.append(height) }
        if let level = profile.highestLevel, !level.isEmpty { parts.append(level) }
        if !profile.city.isEmpty { parts.append(profile.city) }
        return parts.joined(separator: " · ")
    }
}
