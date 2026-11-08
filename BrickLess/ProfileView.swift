import SwiftUI

// One common support contact for every user (Guideline 1.2 requires
// published contact information). This must be an inbox RJ actually
// reads, because reports are meant to be acted on within 24 hours.
// If support@brickless.app is not set up as a mailbox yet, point this
// at an inbox that is, before submitting to the App Store.
private let supportEmail = "support@brickless.app"

/// The player's own profile, opened from Recreational > My Profile.
struct ProfileView: View {
    @ObservedObject var session: SessionStore
    @State private var showingSetup = false
    @State private var showingDeleteConfirm = false
    @State private var deleteError: String?

    var body: some View {
        VStack(spacing: 16) {
            if let profile = session.profile {
                Text(String(profile.displayName.prefix(1)).uppercased())
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 96, height: 96)
                    .background(Color.red)
                    .clipShape(Circle())

                Text(profile.displayName)
                    .font(.title.bold())
                Text("@\(profile.username)")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    row("Email", profile.email)
                    row("Position", profile.position)
                    row("Skill", profile.skillLevel)
                    if !profile.sports.isEmpty {
                        row("Sports", profile.sports.joined(separator: ", "))
                    }
                    if !profile.city.isEmpty {
                        row("City", profile.city)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Button("Edit Profile") { showingSetup = true }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)

                NavigationLink("My Bookings", destination: MyBookingsView())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                ProgressView()
            }

            Link("Contact support: \(supportEmail)", destination: URL(string: "mailto:\(supportEmail)")!)
                .font(.footnote)
                .padding(.top, 8)

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
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
