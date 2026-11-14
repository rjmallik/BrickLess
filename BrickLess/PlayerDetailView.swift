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
            ProfileAvatarView(displayName: profile.displayName,
                              photoURL: profile.photoURL, size: 64)
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
            statRow("City", profile.city.isEmpty ? nil : profile.city)
            // Per-sport detail: each sport the player opted in to, with
            // its positions, skill level and highest level. Legacy
            // profiles (single position/skill) show as one sport section.
            ForEach(profile.sportProfiles.isEmpty ? [legacySportProfile(of: profile)] : profile.sportProfiles, id: \.sport) { sportProfile in
                VStack(alignment: .leading, spacing: 4) {
                    Text(sportProfile.sport).font(.headline)
                    statRow("Positions", sportProfile.positions.joined(separator: ", "))
                    statRow("Skill level", sportProfile.skillLevel)
                    statRow("Highest level", sportProfile.highestLevel)
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// A legacy profile (single position/skill, before per-sport detail)
    /// shown as one sport section for its first sport.
    private func legacySportProfile(of profile: UserProfile) -> SportProfile {
        SportProfile(sport: profile.sports.first ?? "Basketball",
                     positions: [profile.position],
                     skillLevel: profile.skillLevel,
                     highestLevel: profile.highestLevel)
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
