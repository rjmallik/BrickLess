import SwiftUI

/// Step 2 of account setup: the player profile.
/// Shown to every new account, and reachable later from My Profile > Edit.
struct ProfileSetupView: View {
    @ObservedObject var session: SessionStore
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var position: String = "Any"
    @State private var skillLevel: String = "Beginner"
    @State private var city: String = ""
    @State private var sports: [String] = []
    @State private var errorMessage: String?
    @State private var usernameTaken: Bool = false

    var body: some View {
        VStack {
            Text("Set up your profile")
                .font(.title2.bold())
            Text("This is what other players see when they find you for a game.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Display name", text: $displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
                .onChange(of: username) { _ in usernameTaken = false }
            if usernameTaken {
                Text("That username is already taken.")
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Picker("Position", selection: $position) {
                ForEach(UserProfile.positions, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            Picker("Skill level", selection: $skillLevel) {
                ForEach(UserProfile.skillLevels, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Sports the player plays. Pick as many as apply; more
            // sports can be added to UserProfile.allSports later.
            VStack(alignment: .leading, spacing: 8) {
                Text("Sports you play")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(UserProfile.allSports, id: \.self) { sport in
                        Button(sport) {
                            if sports.contains(sport) {
                                sports.removeAll { $0 == sport }
                            } else {
                                sports.append(sport)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(sports.contains(sport) ? Color.blue : Color(.systemGray5))
                        .foregroundColor(sports.contains(sport) ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)

            TextField("City (optional)", text: $city)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage).foregroundColor(.red).padding(.horizontal)
            }

            if session.isLoading {
                ProgressView().padding()
            } else {
                Button("Save Profile") {
                    errorMessage = nil
                    session.saveProfile(displayName: displayName, username: username,
                                        position: position, skillLevel: skillLevel,
                                        city: city, sports: sports) { error in
                        if error == "That username is already taken." {
                            usernameTaken = true
                        }
                        errorMessage = error
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .padding()
            }

            Spacer()
        }
        .padding(.vertical)
        .onAppear {
            // Pre-fill from the account created in step 1.
            if let profile = session.profile {
                displayName = profile.displayName
                username = profile.username
                position = profile.position
                skillLevel = profile.skillLevel
                city = profile.city
                sports = profile.sports
            }
        }
    }
}
