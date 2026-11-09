import SwiftUI

/// Add Friends + My Guys, in one place.
/// Search players by username, send a friend request, accept or decline
/// incoming requests, and see your friends list.
struct FriendsView: View {
    @ObservedObject var session: SessionStore
    @StateObject private var store = FriendsStore()
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0 friends, 1 add, 2 requests
    @State private var reportTarget: UserProfile?

    init(session: SessionStore, selectedTab: Int = 0) {
        self.session = session
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("My Guys").tag(0)
                Text("Add Friends").tag(1)
                Text("Requests").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedTab {
            case 1: addFriends
            case 2: requests
            default: friendsList
            }
            Spacer()
        }
        .navigationTitle("Friends")
        .onAppear { store.startListening() }
        .alert("Report user", isPresented: Binding(
            get: { reportTarget != nil },
            set: { if !$0 { reportTarget = nil } }
        )) {
            Button("Spam") { report(reason: "Spam") }
            Button("Harassment") { report(reason: "Harassment") }
            Button("Inappropriate content") { report(reason: "Inappropriate content") }
            Button("Other") { report(reason: "Other") }
            Button("Cancel", role: .cancel) { reportTarget = nil }
        } message: {
            Text("Reports are reviewed and acted on within 24 hours.")
        }
    }

    private func report(reason: String) {
        guard let target = reportTarget else { return }
        store.reportUser(target, reason: reason)
        reportTarget = nil
    }

    private var friendsList: some View {
        Group {
            if store.friends.isEmpty {
                Text("No friends yet. Search for players to add them.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List(store.friends) { friend in
                    HStack {
                        Text(String(friend.displayName.prefix(1)).uppercased())
                            .font(.headline).foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue).clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(friend.displayName).font(.headline)
                            Text("@\(friend.username) · \(friend.position)")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Remove") { store.removeFriend(friend) }
                            .font(.footnote).foregroundColor(.red)
                    }
                    .contextMenu {
                        Button("Block", role: .destructive) { store.blockUser(friend) }
                        Button("Report") { reportTarget = friend }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var addFriends: some View {
        VStack {
            TextField("Search by username", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
                .onChange(of: searchText) { store.searchUsers(query: searchText) }

            if store.isLoading {
                ProgressView().padding()
            }
            List(store.searchResults) { profile in
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.displayName).font(.headline)
                        Text("@\(profile.username) · \(profile.position)")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Add") {
                        store.sendRequest(to: profile,
                                          fromUsername: session.profile?.username ?? "")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.green).cornerRadius(8)
                }
                .contextMenu {
                    Button("Block", role: .destructive) { store.blockUser(profile) }
                    Button("Report") { reportTarget = profile }
                }
            }
            .listStyle(.plain)
        }
    }

    private var requests: some View {
        List {
            Section("Incoming") {
                if store.incomingRequests.isEmpty {
                    Text("No pending requests.").foregroundColor(.secondary)
                }
                ForEach(store.incomingRequests) { request in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(request.fromUsername).font(.headline)
                            Text("wants to be your friend")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Accept") { store.respond(to: request, accept: true) }
                            .foregroundColor(.white).padding(.horizontal, 10)
                            .padding(.vertical, 6).background(Color.green).cornerRadius(8)
                        Button("Decline") { store.respond(to: request, accept: false) }
                            .foregroundColor(.red)
                    }
                }
            }
            Section("Sent") {
                if store.outgoingRequests.isEmpty {
                    Text("No sent requests.").foregroundColor(.secondary)
                }
                ForEach(store.outgoingRequests) { request in
                    Text("@\(request.toUsername) — pending")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }
}
