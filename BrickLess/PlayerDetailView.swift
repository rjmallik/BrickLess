import SwiftUI

/// A player's full profile, opened from PlayersView.
/// Add Friend sends a request through FriendsStore; Block removes them
/// from discovery everywhere. The Add Friend button is hidden on your
/// own profile.
struct PlayerDetailView: View {
    let profile: UserProfile
    @ObservedObject var session: SessionStore
    @StateObject private var friendsStore = FriendsStore()
    @Environment(\.dismiss) private var dismiss
    @State private var showingBlockConfirm = false

    var isOwnProfile: Bool {
        profile.id == session.profile?.id
    }

    var isFriend: Bool {
        friendsStore.friends.contains { $0.id == profile.id }
    }

    var requestSent: Bool {
        friendsStore.outgoingRequests.contains { $0.toUid == profile.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                stats
                if !isOwnProfile {
                    actions
                }
            }
            .padding()
        }
        .navigationTitle(profile.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { friendsStore.startListening() }
        .alert("Block @\(profile.username)?", isPresented: $showingBlockConfirm) {
            Button("Block", role: .destructive) {
                friendsStore.blockUser(profile)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will not be able to find you, and you will not see them in Players or Friends.")
        }
    }

    private var header: some View {
        HStack {
            Text(String(profile.displayName.prefix(1)).uppercased())
                .font(.largeTitle).foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color.blue).clipShape(Circle())
            VStack(alignment: .leading) {
                Text(profile.displayName).font(.title2).bold()
                Text("@\(profile.username)").foregroundColor(.secondary)
            }
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 8) {
            statRow("Age", profile.age.map(String.init))
            statRow("Height", PlayersStore.heightString(inches: profile.heightInches))
            statRow("Highest level", profile.highestLevel)
            statRow("Position", profile.position)
            statRow("Skill level", profile.skillLevel)
            statRow("City", profile.city.isEmpty ? nil : profile.city)
            statRow("Sports", profile.sports.isEmpty ? nil : profile.sports.joined(separator: ", "))
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack {
                Text(label).foregroundColor(.secondary)
                Spacer()
                Text(value)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if isFriend {
                Text("You are friends").foregroundColor(.secondary)
            } else if requestSent {
                Text("Friend request sent").foregroundColor(.secondary)
            } else {
                Button("Add Friend") {
                    friendsStore.sendRequest(to: profile,
                                             fromUsername: session.profile?.username ?? "")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Color.green).cornerRadius(10)
            }
            Button("Block", role: .destructive) { showingBlockConfirm = true }
        }
    }
}
