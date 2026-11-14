import SwiftUI

// No support contact is published in the app right now (Nov 13, 2026:
// RJ removed his personal Gmail; a proper support email comes later).

/// The player's own profile, opened from Recreational > My Profile.
struct ProfileView: View {
    @ObservedObject var session: SessionStore
    @State private var showingSetup = false
    @State private var showingDeleteConfirm = false
    @State private var deleteError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
            if let profile = session.profile {
                ProfileAvatarView(displayName: profile.displayName,
                                  photoURL: profile.photoURL, size: 96)

                Text(profile.displayName)
                    .font(.title.bold())
                Text("@\(profile.username)")
                    .foregroundColor(.secondary)

                // How good the player is, as badges. Shown only for the
                // fields the player provided; older profiles may have none.
                if profile.age != nil || profile.heightInches != nil || profile.highestLevel != nil {
                    HStack(spacing: 8) {
                        if let age = profile.age {
                            statBadge(value: "\(age)", label: "Age")
                        }
                        if let height = profile.heightFormatted {
                            statBadge(value: height, label: "Height")
                        }
                        if let level = profile.highestLevel {
                            statBadge(value: level, label: "Highest level")
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // The player's own email, from Auth, not the profile:
                    // the profile document holds no email, so no other
                    // user can read it.
                    row("Email", session.firebaseUser?.email ?? "")
                    if !profile.city.isEmpty {
                        row("City", profile.city)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // Per-sport detail: each sport the player opted in to,
                // with its positions, skill level and highest level.
                // Falls back to the primary position/skill for legacy
                // profiles that predate per-sport detail.
                ForEach(profile.sportProfiles.isEmpty ? [legacySportProfile(of: profile)] : profile.sportProfiles, id: \.sport) { sportProfile in
                    let style = sportStyle(for: sportProfile.sport)
                    VStack(alignment: .leading, spacing: 4) {
                        Label(sportProfile.sport, systemImage: style.symbol)
                            .font(.headline)
                            .foregroundColor(style.color)
                        row("Positions", sportProfile.positions.joined(separator: ", "))
                        row("Skill level", sportProfile.skillLevel)
                        if let level = sportProfile.highestLevel {
                            row("Highest level", level)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Button("Edit Profile") { showingSetup = true }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PlayMatchColors.brand)
                    .cornerRadius(8)
                    .padding(.horizontal)

            } else {
                ProgressView()
            }

            Button("Sign Out", role: .destructive) {
                session.signOut()
            }
            .padding(.top, 4)

            Button("Delete Account", role: .destructive) {
                showingDeleteConfirm = true
            }
            .font(.footnote)
            .padding(.bottom, 4)

            if let deleteError {
                Text(deleteError).foregroundColor(.red).padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        }
        .sheet(isPresented: $showingSetup) {
            ProfileSetupView(session: session)
        }
        .alert("Delete your account?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                session.deleteAccount { error in
                    deleteError = error
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your profile, username and account. This cannot be undone.")
        }
        .navigationTitle("My Profile")
        .appBackground()
    }

    /// A legacy profile (single position/skill, before per-sport detail)
    /// shown as one sport section for its first sport, so old accounts
    /// keep displaying until they re-save.
    private func legacySportProfile(of profile: UserProfile) -> SportProfile {
        SportProfile(sport: profile.sports.first ?? "Basketball",
                     positions: [profile.position],
                     skillLevel: profile.skillLevel,
                     highestLevel: profile.highestLevel)
    }

    /// The pin style (ball icon + color) for a profile display name
    /// ("American Football" -> football). Unknown names fall back to
    /// basketball.
    private func sportStyle(for displayName: String) -> (symbol: String, color: Color) {
        SportTabs.pinStyle(forTag: SportTabs.tag(forDisplayName: displayName) ?? "basketball")
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

/// A player's avatar: their uploaded photo when they have one,
/// otherwise a circle with the first letter of their display name.
/// Shared by My Profile, the players list, Friends, and player detail,
/// so every avatar in the app looks the same.
struct ProfileAvatarView: View {
    let displayName: String
    let photoURL: String?
    var size: CGFloat = 64

    var body: some View {
        if let photoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                default:
                    initialCircle
                }
            }
        } else {
            initialCircle
        }
    }

    private var initialCircle: some View {
        Text(String(displayName.prefix(1)).uppercased())
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(PlayMatchColors.brand)
            .clipShape(Circle())
    }
}
