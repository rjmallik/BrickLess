import SwiftUI

/// Discover players: browse everyone, search by username, and filter by
/// highest level played and city. Tapping a player opens their profile.
/// Matches the FriendsView patterns (search TextField, blue initial
/// avatar, plain list).
struct PlayersView: View {
    @ObservedObject var session: SessionStore
    @StateObject private var store = PlayersStore()

    init(session: SessionStore) {
        self.session = session
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search by username", text: $store.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: store.searchText) { store.searchUsers() }

            filters
                .padding(.horizontal)
                .padding(.vertical, 8)

            if store.isLoading && store.visiblePlayers.isEmpty {
                ProgressView().padding()
            } else if store.visiblePlayers.isEmpty {
                emptyState
            } else {
                playerList
            }
            Spacer()
        }
        .navigationTitle("Players")
        .onAppear {
            if store.players.isEmpty && store.searchResults.isEmpty {
                store.refresh()
            } else {
                store.refreshBlockedUids()
            }
        }
    }

    private var filters: some View {
        HStack {
            Menu {
                Picker("Level", selection: $store.levelFilter) {
                    Text("All levels").tag("All")
                    ForEach(PlayersStore.levels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
            } label: {
                Label(store.levelFilter == "All" ? "Level" : store.levelFilter,
                      systemImage: "line.3.horizontal.decrease.circle")
            }
            TextField("City", text: $store.cityFilter)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
    }

    private var playerList: some View {
        List(store.visiblePlayers) { profile in
            NavigationLink(destination: PlayerDetailView(profile: profile, session: session)) {
                playerCard(profile)
            }
            .onAppear {
                // Load the next page when the last shown player appears.
                if profile.id == store.visiblePlayers.last?.id {
                    store.loadNextPage()
                }
            }
        }
        .listStyle(.plain)
        .refreshable { store.refresh() }
        .overlay(alignment: .bottom) {
            if store.isLoading && !store.visiblePlayers.isEmpty {
                ProgressView().padding(8)
            }
        }
    }

    private var emptyState: some View {
        Text(store.isSearching
             ? "No players match that search."
             : "No players found. Try clearing the filters.")
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
    }

    private func playerCard(_ profile: UserProfile) -> some View {
        let stats = PlayersStore.statLine(for: profile)
        return HStack {
            Text(String(profile.displayName.prefix(1)).uppercased())
                .font(.headline).foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.blue).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName).font(.headline)
                Text("@\(profile.username) · \(profile.position)")
                    .font(.subheadline).foregroundColor(.secondary)
                if !stats.isEmpty {
                    Text(stats).font(.footnote).foregroundColor(.secondary)
                }
                if !profile.sports.isEmpty {
                    Text(profile.sports.joined(separator: ", "))
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
        }
    }
}
