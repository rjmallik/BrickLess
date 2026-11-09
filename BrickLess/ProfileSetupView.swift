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
    @State private var sports: [String] = ["Basketball"] // launch sport, pre-selected
    // How good the player is. Level is required (defaults to Recreational);
    // age and height are optional but prompted.
    @State private var ageText: String = ""
    @State private var includeHeight: Bool = false
    @State private var heightFeet: Int = 6
    @State private var heightInches: Int = 0
    @State private var highestLevel: String = UserProfile.defaultHighestLevel
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
                .onChange(of: username) { usernameTaken = false }
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

            Picker("Highest level played", selection: $highestLevel) {
                ForEach(UserProfile.highestLevels, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            TextField("Age (optional)", text: $ageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal)

            // Height is optional: the toggle reveals the feet/inches pickers.
            Toggle("Add my height", isOn: $includeHeight)
                .padding(.horizontal)
            if includeHeight {
                HStack {
                    Picker("Feet", selection: $heightFeet) {
                        ForEach(UserProfile.heightFeetRange, id: \.self) { Text("\($0) ft") }
                    }
                    .pickerStyle(.menu)
                    Picker("Inches", selection: $heightInches) {
                        ForEach(0..<12, id: \.self) { Text("\($0) in") }
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    Text(UserProfile.formattedHeight(heightFeet * 12 + heightInches))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

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
                    // Age is optional, but when entered it must be a number in range.
                    let age: Int?
                    if ageText.trimmingCharacters(in: .whitespaces).isEmpty {
                        age = nil
                    } else if let parsed = Int(ageText),
                              UserProfile.ageRange.contains(parsed) {
                        age = parsed
                    } else {
                        errorMessage = "Enter an age between 13 and 100, or leave it blank."
                        return
                    }
                    let height: Int? = includeHeight ? heightFeet * 12 + heightInches : nil
                    session.saveProfile(displayName: displayName, username: username,
                                        position: position, skillLevel: skillLevel,
                                        city: city, sports: sports,
                                        age: age, heightInches: height,
                                        highestLevel: highestLevel) { error in
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
                if let age = profile.age {
                    ageText = String(age)
                }
                if let inches = profile.heightInches {
                    includeHeight = true
                    heightFeet = min(max(inches / 12, UserProfile.heightFeetRange.lowerBound),
                                     UserProfile.heightFeetRange.upperBound)
                    heightInches = inches % 12
                }
                highestLevel = profile.highestLevel ?? UserProfile.defaultHighestLevel
            }
        }
    }
}
