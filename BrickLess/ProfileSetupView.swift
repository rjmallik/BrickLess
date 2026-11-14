import SwiftUI

/// Step 2 of account setup: the player profile.
/// Shown to every new account, and reachable later from My Profile > Edit.
///
/// One profile, with per-sport detail: the player opts in to the sports
/// they play (all phases except golf), and each opted-in sport gets its
/// own positions, skill level and highest level played. Positions are
/// per-sport (a basketball point guard is not a soccer goalkeeper), the
/// skill level is per-sport, and the highest level is optional (nil =
/// not specified) and goes up to Professional.
struct ProfileSetupView: View {
    @ObservedObject var session: SessionStore
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var city: String = ""
    @State private var sports: [String] = ["Basketball"] // launch sport, pre-selected
    /// Per-sport drafts, keyed by sport display name. Created when a sport
    /// is opted in, removed when it is opted out.
    @State private var sportDrafts: [String: SportProfile] = [:]
    // How good the player is. Level is required (defaults to Recreational);
    // age and height are optional but prompted.
    @State private var ageText: String = ""
    @State private var includeHeight: Bool = false
    @State private var heightFeet: Int = 6
    @State private var heightInches: Int = 0
    @State private var errorMessage: String?
    @State private var usernameTaken: Bool = false
    /// Location permission, offered at signup so the map works the first
    /// time the user opens it. Skippable by design: the system prompt
    /// fires at most once, and Save Profile below always works, with or
    /// without location. The map still asks on first open as a fallback.
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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

                // Sports the player plays. Pick as many as apply; each
                // opted-in sport gets its own section below.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sports you play")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 8) {
                        ForEach(UserProfile.allSports, id: \.self) { sport in
                            Button {
                                toggleSport(sport)
                            } label: {
                                Label(sport, systemImage: sportStyle(for: sport).symbol)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(sports.contains(sport) ? sportStyle(for: sport).color : Color(.systemGray5))
                            .foregroundColor(sports.contains(sport) ? .white : .primary)
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)

                // One section per opted-in sport: positions for that sport,
                // the skill level for that sport, and the highest level
                // played for that sport (optional).
                ForEach(sports, id: \.self) { sport in
                    SportSetupSection(draft: draftBinding(for: sport))
                }

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

                TextField("City (optional)", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // Location, offered here at signup so the map works the first
                // time it opens. Never required: Save Profile below always
                // works, and the map asks again on first open if skipped.
                VStack(alignment: .leading, spacing: 8) {
                    Text("PlayMatch uses your location to show courts and fields near you.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    switch LocationManager.setupPrompt(for: locationManager.authorizationStatus) {
                    case .offerToEnable:
                        Button("Allow Location Access") {
                            locationManager.requestPermission()
                        }
                        .foregroundColor(PlayMatchColors.brand)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PlayMatchColors.brand))
                        Text("Optional — you can skip this and the map will ask when you first open it.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    case .enabled:
                        Label("Location is on — we'll show courts and fields near you.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    case .unavailable:
                        Text("Location is off. You can still use PlayMatch — the map will show downtown Seattle. Turn it on later in Settings.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red).padding(.horizontal)
                }

                if session.isLoading {
                    ProgressView().padding()
                } else {
                    Button("Save Profile") {
                        errorMessage = nil
                        guard !sports.isEmpty else {
                            errorMessage = "Pick at least one sport you play."
                            return
                        }
                        // Age is optional, but when entered it must be a number in range.
                        let age: Int?
                        switch UserProfile.parseAge(ageText) {
                        case .blank:
                            age = nil
                        case .valid(let value):
                            age = value
                        case .invalid:
                            errorMessage = "Enter an age between 13 and 100, or leave it blank."
                            return
                        }
                        let height: Int? = includeHeight ? heightFeet * 12 + heightInches : nil
                        // Per-sport detail, in allSports order, for opted-in sports only.
                        let sportProfiles = sports.compactMap { sportDrafts[$0] }
                        session.saveProfile(displayName: displayName, username: username,
                                            city: city, sports: sports,
                                            sportProfiles: sportProfiles,
                                            age: age, heightInches: height) { error in
                            if error == "That username is already taken." {
                                usernameTaken = true
                            }
                            errorMessage = error
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PlayMatchColors.brand)
                    .cornerRadius(8)
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            // Pre-fill from the account created in step 1.
            if let profile = session.profile {
                displayName = profile.displayName
                username = profile.username
                city = profile.city
                sports = profile.sports.isEmpty ? ["Basketball"] : profile.sports
                if !profile.sportProfiles.isEmpty {
                    sportDrafts = Dictionary(uniqueKeysWithValues:
                        profile.sportProfiles.map { ($0.sport, $0) })
                } else if !profile.sports.isEmpty || !profile.position.isEmpty {
                    // Legacy profile (single position/skill, before per-sport
                    // detail): carry it into the first sport's draft.
                    let firstSport = profile.sports.first ?? "Basketball"
                    sportDrafts[firstSport] = SportProfile(
                        sport: firstSport,
                        positions: [profile.position],
                        skillLevel: profile.skillLevel,
                        highestLevel: profile.highestLevel)
                }
                if let age = profile.age {
                    ageText = String(age)
                }
                if let inches = profile.heightInches {
                    includeHeight = true
                    heightFeet = min(max(inches / 12, UserProfile.heightFeetRange.lowerBound),
                                     UserProfile.heightFeetRange.upperBound)
                    heightInches = inches % 12
                }
            }
        }
    }

    /// Opt in or out of a sport. Opting in starts a fresh draft
    /// (positions Any, Beginner, no highest level); opting out drops it.
    private func toggleSport(_ sport: String) {
        if sports.contains(sport) {
            sports.removeAll { $0 == sport }
            sportDrafts.removeValue(forKey: sport)
        } else {
            sports.append(sport)
            sports.sort { UserProfile.allSports.firstIndex(of: $0) ?? 0
                         < UserProfile.allSports.firstIndex(of: $1) ?? 0 }
            sportDrafts[sport] = SportProfile(sport: sport, positions: ["Any"],
                                              skillLevel: "Beginner", highestLevel: nil)
        }
    }

    /// The pin style (ball icon + color) for a profile display name
    /// ("American Football" -> football). Unknown names fall back to
    /// basketball.
    private func sportStyle(for displayName: String) -> (symbol: String, color: Color) {
        SportTabs.pinStyle(forTag: SportTabs.tag(forDisplayName: displayName) ?? "basketball")
    }

    /// Binding to a sport's draft, creating a fresh one if missing.
    private func draftBinding(for sport: String) -> Binding<SportProfile> {
        Binding(
            get: { sportDrafts[sport] ?? SportProfile(sport: sport, positions: ["Any"],
                                                      skillLevel: "Beginner", highestLevel: nil) },
            set: { sportDrafts[sport] = $0 }
        )
    }
}

/// One opted-in sport's setup: its positions, its skill level, and its
/// highest level played (optional, up to Professional).
private struct SportSetupSection: View {
    @Binding var draft: SportProfile

    /// The ball icon + color for this section's sport.
    private var sportStyle: (symbol: String, color: Color) {
        SportTabs.pinStyle(forTag: SportTabs.tag(forDisplayName: draft.sport) ?? "basketball")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(draft.sport, systemImage: sportStyle.symbol)
                .font(.headline)
                .foregroundColor(sportStyle.color)
            Text("Positions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], alignment: .leading, spacing: 8) {
                ForEach(UserProfile.positions(forSport: draft.sport), id: \.self) { position in
                    Button(position) {
                        togglePosition(position)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(draft.positions.contains(position) ? sportStyle.color : Color(.systemGray5))
                    .foregroundColor(draft.positions.contains(position) ? .white : .primary)
                    .cornerRadius(16)
                }
            }
            Text("Level you're at")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("Skill level", selection: $draft.skillLevel) {
                ForEach(UserProfile.skillLevels, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            // Highest level is optional: "Not specified" is the default,
            // and the range runs up to Professional for players who played pro.
            Text("Highest level played (optional)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker("Highest level played", selection: $draft.highestLevel) {
                Text("Not specified").tag(nil as String?)
                ForEach(UserProfile.highestLevels, id: \.self) { Text($0).tag($0 as String?) }
            }
            .pickerStyle(.menu)
            Text("Pick the highest level you played up to — including Professional if you played pro — or leave it blank.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// Multi-select positions. "Any" is exclusive: picking it clears the
    /// rest, and picking anything else clears "Any". At least one stays
    /// selected, falling back to "Any".
    private func togglePosition(_ position: String) {
        if position == "Any" {
            draft.positions = ["Any"]
            return
        }
        var positions = draft.positions.filter { $0 != "Any" }
        if positions.contains(position) {
            positions.removeAll { $0 == position }
        } else {
            positions.append(position)
        }
        draft.positions = positions.isEmpty ? ["Any"] : positions
    }
}
