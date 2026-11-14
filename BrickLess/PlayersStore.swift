import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// Browse and discover players, not just people you already know.
///
/// Browse is paginated: 20 matching profiles at a time, ordered by
/// `usernameLower`, paging with `start(afterDocument:)`. Search reuses
/// the username-prefix pattern from FriendsStore.
///
/// Filters cover ALL players, not just the loaded pages:
/// - Level is a server-side equality filter (`whereField("highestLevel",
///   isEqualTo:)`, see `browseQueryPlan`), so the query itself only
///   returns that level. It needs the composite index `users:
///   highestLevel ASC + usernameLower ASC` in firestore.indexes.json;
///   until that index is deployed and built, picking a level fails
///   with a Firestore index error.
/// - City has no server-side equivalent: Firestore has no substring
///   ("contains") query. The browse scan keeps fetching raw 20-doc
///   pages and applies the case-insensitive substring match
///   client-side until a full page of matches is found or the
///   collection is exhausted, so a city filter still sees every
///   player. Tradeoff: a city that matches almost nobody scans the
///   whole users collection in 20-doc reads. At launch scale that is
///   a handful of reads; if the user base grows, add a normalized
///   `cityLower` field at profile-save time and switch city to a
///   prefix range query. That would also drop substring matching
///   ("eattle" would stop matching "Seattle"), so it is a product
///   call, not just a perf fix. The fill-the-page scan was chosen
///   over `cityLower` because it needs no schema migration and no
///   backfill: existing profiles, which have no `cityLower`, keep
///   working as-is.
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

    /// Guards against stale page loads: `refresh()` bumps this, and a
    /// page-load completion whose generation no longer matches is
    /// ignored instead of appending to the fresh list. Filter changes
    /// trigger refreshes, so overlapping loads are the common case,
    /// not an edge case.
    private var fetchGeneration = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Filter changes re-run the query from scratch: the loaded
        // players only ever match the filters that were active when
        // they were fetched, so keeping them would show stale results.
        // Level taps are discrete, so they refresh immediately; city
        // is typed, so it waits until the user pauses, or every
        // keystroke would re-scan the collection.
        $levelFilter
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
        $cityFilter
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    var uid: String? { Auth.auth().currentUser?.uid }

    /// Highest level played, in ascending order. Single source of truth
    /// is UserProfile.highestLevels — these strings must match what
    /// profile setup stores, or the level filter will never match.
    static let levels = UserProfile.highestLevels

    var isSearching: Bool {
        searchText.trimmingCharacters(in: .whitespaces).count >= 2
    }

    /// The browse/search filter, as a pure function: level (unless
    /// "All") must match highestLevel, and a non-blank city filter
    /// must appear in the profile city (case-insensitive).
    static func filteredPlayers(_ profiles: [UserProfile], levelFilter: String, cityFilter: String) -> [UserProfile] {
        profiles.filter { profile in
            if levelFilter != "All", profile.highestLevel != levelFilter { return false }
            let city = cityFilter.trimmingCharacters(in: .whitespaces)
            if !city.isEmpty, !profile.city.localizedCaseInsensitiveContains(city) { return false }
            return true
        }
    }

    /// Pure description of the server-side browse query for a set of
    /// filters, so the query logic is testable without Firestore.
    /// - Level: Firestore can filter it (`whereField("highestLevel",
    ///   isEqualTo:)`), nil when the filter is "All".
    /// - City: Firestore cannot do substring matching, so there is no
    ///   server-side city filter; the trimmed city string is returned
    ///   so the caller can apply it client-side while scanning raw
    ///   pages (`filteredPlayers` with level "All").
    struct BrowseQueryPlan: Equatable {
        var levelEquals: String?
        var citySubstring: String
    }

    static func browseQueryPlan(levelFilter: String, cityFilter: String) -> BrowseQueryPlan {
        BrowseQueryPlan(
            levelEquals: levelFilter == "All" ? nil : levelFilter,
            citySubstring: cityFilter.trimmingCharacters(in: .whitespaces)
        )
    }

    /// Whether the fill-the-page scan should fetch another raw page:
    /// keep going while we still need more matches for a full page
    /// and the last raw page came back full, meaning more raw
    /// documents may exist. Stops as soon as the page is full or a
    /// short raw page proves the collection is exhausted.
    static func shouldFetchAnotherPage(matchesSoFar: Int, pageSize: Int, rawPageWasFull: Bool) -> Bool {
        matchesSoFar < pageSize && rawPageWasFull
    }

    /// Players to show: search results while searching, otherwise the
    /// browsed pages. Browse players already match the filters (level
    /// server-side, city via the fill-the-page scan), so this is a
    /// no-op safety net for them; for search results it is the filter
    /// itself, since search returns at most 20 prefix matches and the
    /// city substring is applied to those in memory.
    var visiblePlayers: [UserProfile] {
        let base = isSearching ? searchResults : players
        return Self.filteredPlayers(base, levelFilter: levelFilter, cityFilter: cityFilter)
    }

    /// First page (or reload). Blocked users are fetched first so they
    /// never appear in the results.
    func refresh() {
        players = []
        searchResults = []
        lastDocument = nil
        hasMore = true
        // A load in flight belongs to the old filters: drop it so its
        // completion cannot append stale players, and clear the loading
        // flag so the fresh load is not blocked by the stale one.
        isLoading = false
        fetchGeneration += 1
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

    /// Next browse page: a full page of players matching the current
    /// filters, not just the next 20 raw profiles. The level filter is
    /// applied server-side; the city filter is applied client-side to
    /// each raw page, and fetching continues until the page is full or
    /// the collection runs out, so filters cover all players instead
    /// of only the loaded pages. No-op while searching, while loading,
    /// or when the scan already reached the end.
    func loadNextPage() {
        guard !isSearching, !isLoading, hasMore else { return }
        isLoading = true
        fetchPage(accumulated: [], generation: fetchGeneration)
    }

    /// One step of the fill-the-page scan: fetch the next raw page of
    /// the level-filtered query, keep the profiles matching the city
    /// filter (and not the user, or blocked), and either append a full
    /// page of matches or fetch another raw page.
    private func fetchPage(accumulated: [UserProfile], generation: Int) {
        let plan = Self.browseQueryPlan(levelFilter: levelFilter, cityFilter: cityFilter)
        var query: Query = db.collection("users")
            .order(by: "usernameLower")
        if let level = plan.levelEquals {
            query = query.whereField("highestLevel", isEqualTo: level)
        }
        query = query.limit(to: pageSize)
        if let lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        query.getDocuments { [weak self] snapshot, error in
            guard let self, generation == self.fetchGeneration else { return }
            if let error {
                self.isLoading = false
                self.errorMessage = SessionStore.friendlyError(error)
                return
            }
            let docs = snapshot?.documents ?? []
            self.lastDocument = docs.last
            let rawPageWasFull = docs.count == self.pageSize
            let matches = Self.filteredPlayers(
                docs.compactMap { try? $0.data(as: UserProfile.self) }
                    .filter { $0.id != self.uid && !self.blockedUids.contains($0.id ?? "") },
                levelFilter: "All", cityFilter: plan.citySubstring)
            let accumulated = accumulated + matches
            if Self.shouldFetchAnotherPage(matchesSoFar: accumulated.count, pageSize: self.pageSize, rawPageWasFull: rawPageWasFull) {
                self.fetchPage(accumulated: accumulated, generation: generation)
                return
            }
            self.isLoading = false
            // The scan only stops on a full page or an exhausted
            // collection, so more matches may exist exactly when more
            // raw documents do.
            self.hasMore = rawPageWasFull
            self.players.append(contentsOf: accumulated)
        }
    }

    /// Username prefix search, same pattern as FriendsStore.searchUsers.
    /// The level filter is applied server-side, so it covers all
    /// prefix matches instead of only the 20 returned; the city
    /// substring is still applied client-side to those results via
    /// `visiblePlayers`, since search has no paging to scan with.
    func searchUsers() {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 2, let uid else {
            searchResults = []
            if players.isEmpty { loadNextPage() }
            return
        }
        isLoading = true
        var query: Query = db.collection("users")
            .order(by: "usernameLower")
            .start(at: [q])
            .end(at: [q + "\u{f8ff}"])
        if levelFilter != "All" {
            query = query.whereField("highestLevel", isEqualTo: levelFilter)
        }
        query
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
