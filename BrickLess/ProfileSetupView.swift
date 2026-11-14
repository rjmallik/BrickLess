import SwiftUI
import PhotosUI
import UIKit
import MapKit

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
    @Environment(\.dismiss) private var dismiss
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
    /// Profile photo (optional): the saved photo URL, a newly picked
    /// photo's data (not yet uploaded), and the picker item. The photo
    /// uploads on Save; removing it clears the URL and deletes the
    /// stored file.
    @State private var photoURL: String?
    @State private var newPhotoData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    /// City autofill: real US place suggestions as the player types
    /// (MapKit, restricted to the United States), plus the suggestion
    /// just tapped, so picking one does not re-trigger suggestions.
    @StateObject private var locationCompleter = LocationSearchCompleter()
    @State private var selectedCitySuggestion: String?
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

                // Profile photo (optional): shown on the profile and in
                // player lists. Picking a new one replaces the current
                // photo; Remove clears it. The photo uploads on Save.
                VStack(spacing: 8) {
                    photoPreview
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images,
                                     photoLibrary: .shared()) {
                            Label(photoURL == nil && newPhotoData == nil ? "Add photo" : "Change photo",
                                  systemImage: "photo")
                        }
                        .foregroundColor(PlayMatchColors.brand)
                        if photoURL != nil || newPhotoData != nil {
                            Button("Remove photo") {
                                photoURL = nil
                                newPhotoData = nil
                                photoPickerItem = nil
                            }
                            .foregroundColor(.red)
                            .font(.footnote)
                        }
                    }
                }
                .onChange(of: photoPickerItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            newPhotoData = data
                        }
                    }
                }

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

                // City, with autofill from real US places: as the player
                // types, MapKit suggests certified US locations (the app
                // is US-only); tapping one fills the field. The field
                // stays free text — suggestions are a convenience, and
                // when MapKit has nothing (e.g. offline) the bundled
                // major-US-cities list fills in instead.
                VStack(alignment: .leading, spacing: 4) {
                    TextField("City (optional)", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .onChange(of: city) { _, newValue in
                            if newValue == selectedCitySuggestion {
                                locationCompleter.suggestions = []
                                return
                            }
                            selectedCitySuggestion = nil
                            locationCompleter.update(query: newValue)
                        }
                    if !locationCompleter.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(locationCompleter.suggestions, id: \.self) { suggestion in
                                Button {
                                    selectCitySuggestion(suggestion)
                                } label: {
                                    Text(suggestion)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                            }
                        }
                        .background(Color.black)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3)))
                    }
                }
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
                        save()
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
        .appBackground()
        .onAppear {
            // Pre-fill from the account created in step 1.
            if let profile = session.profile {
                displayName = profile.displayName
                username = profile.username
                city = profile.city
                photoURL = profile.photoURL
                newPhotoData = nil
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

    /// The photo preview: the newly picked photo first, then the
    /// saved photo, then the initial-letter circle.
    private var photoPreview: some View {
        Group {
            if let newPhotoData, let image = UIImage(data: newPhotoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            } else {
                ProfileAvatarView(displayName: displayName.isEmpty ? username : displayName,
                                  photoURL: photoURL, size: 96)
            }
        }
    }

    /// Validates the form, uploads a newly picked photo first (when
    /// there is one), then saves the profile with the photo URL.
    /// Removing the photo clears the URL and deletes the stored file.
    private func save() {
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
        let hadPhoto = session.profile?.photoURL != nil

        if let newPhotoData {
            guard let image = UIImage(data: newPhotoData) else {
                errorMessage = "That photo could not be read. Pick another one."
                return
            }
            session.uploadProfilePhoto(image) { result in
                switch result {
                case .success(let url):
                    commitSave(age: age, height: height, sportProfiles: sportProfiles,
                               photoURL: url, hadPhoto: hadPhoto)
                case .failure:
                    errorMessage = "Couldn't upload your photo. Try again."
                }
            }
        } else {
            commitSave(age: age, height: height, sportProfiles: sportProfiles,
                       photoURL: photoURL, hadPhoto: hadPhoto)
        }
    }

    /// The Firestore save itself, shared by the with-photo and
    /// without-photo paths. A removed photo's stored file is deleted
    /// once the save succeeds and the profile no longer points at it.
    private func commitSave(age: Int?, height: Int?, sportProfiles: [SportProfile],
                            photoURL: String?, hadPhoto: Bool) {
        session.saveProfile(displayName: displayName, username: username,
                            city: city, sports: sports,
                            sportProfiles: sportProfiles,
                            age: age, heightInches: height,
                            photoURL: photoURL) { error in
            if error == "That username is already taken." {
                usernameTaken = true
            }
            errorMessage = error
            if error == nil, hadPhoto, photoURL == nil {
                session.deleteProfilePhoto()
            }
            // Editing from My Profile: close the edit sheet on a
            // successful save and go back to the profile. The
            // first-time setup flow is unaffected: dismiss is a
            // no-op when the view was not presented as a sheet,
            // and the needsProfileSetup gate flips to Home.
            if error == nil {
                dismiss()
            }
        }
    }

    /// A tapped city suggestion fills the field. Remembering it here
    /// stops the field's onChange from re-querying MapKit for the
    /// text that was just picked.
    private func selectCitySuggestion(_ suggestion: String) {
        selectedCitySuggestion = suggestion
        city = suggestion
        locationCompleter.suggestions = []
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

/// City autofill for profile setup. The app is US-only, so suggestions
/// are real US places: MapKit's completer first (restricted to the
/// United States by region), with a bundled list of major US cities
/// as the fallback when MapKit has nothing (e.g. offline). The pure
/// helpers are unit-tested in LocationSetupTests.
enum LocationSuggestions {
    /// "City, ST" for a MapKit completion: the title plus the first
    /// part of the subtitle (usually the state, e.g. "California, United
    /// States" -> "California"). A bare title stays bare.
    static func displayText(title: String, subtitle: String) -> String {
        let title = title.trimmingCharacters(in: .whitespaces)
        let subtitle = subtitle.trimmingCharacters(in: .whitespaces)
        guard !subtitle.isEmpty else { return title }
        let first = subtitle.split(separator: ",", maxSplits: 1).first
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? subtitle
        return "\(title), \(first)"
    }

    /// Prefix matches on the city name first ("san" -> San Francisco,
    /// San Diego, ...), then substring matches, alphabetically, capped
    /// at `limit`. Case-insensitive; a blank query matches nothing.
    /// Pure so the unit tests cover it without MapKit.
    static func matchingCities(query: String, from cities: [String] = majorUSCities,
                               limit: Int = 5) -> [String] {
        let query = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return [] }
        let prefix = cities.filter {
            $0.split(separator: ",", maxSplits: 1).first
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix(query) } ?? false
        }
        let rest = cities.filter {
            !prefix.contains($0) && $0.lowercased().contains(query)
        }
        return Array((prefix.sorted() + rest.sorted()).prefix(limit))
    }

    /// Major US cities ("City, ST"), the offline fallback for city
    /// autofill and the list the unit tests match against.
    static let majorUSCities = [
        "New York, NY", "Los Angeles, CA", "Chicago, IL", "Houston, TX",
        "Phoenix, AZ", "Philadelphia, PA", "San Antonio, TX", "San Diego, CA",
        "Dallas, TX", "San Jose, CA", "Austin, TX", "Jacksonville, FL",
        "Fort Worth, TX", "Columbus, OH", "Charlotte, NC", "San Francisco, CA",
        "Indianapolis, IN", "Seattle, WA", "Denver, CO", "Oklahoma City, OK",
        "Nashville, TN", "Washington, DC", "El Paso, TX", "Las Vegas, NV",
        "Boston, MA", "Detroit, MI", "Portland, OR", "Louisville, KY",
        "Memphis, TN", "Baltimore, MD", "Milwaukee, WI", "Albuquerque, NM",
        "Tucson, AZ", "Mesa, AZ", "Sacramento, CA", "Atlanta, GA",
        "Kansas City, MO", "Colorado Springs, CO", "Miami, FL", "Raleigh, NC",
        "Omaha, NE", "Long Beach, CA", "Virginia Beach, VA", "Oakland, CA",
        "Minneapolis, MN", "Bakersfield, CA", "Tulsa, OK", "Tampa, FL",
        "Arlington, TX", "New Orleans, LA", "Wichita, KS", "Cleveland, OH",
        "Irvine, CA", "Cincinnati, OH", "Newark, NJ", "St. Louis, MO",
        "Pittsburgh, PA", "Greensboro, NC", "St. Paul, MN", "Anchorage, AK",
        "Honolulu, HI", "Salt Lake City, UT", "Boise, ID", "Richmond, VA",
        "Spokane, WA", "Tacoma, WA", "Santa Cruz, CA", "Berkeley, CA",
        "Palo Alto, CA", "Sunnyvale, CA", "Fremont, CA", "Santa Clara, CA",
    ]
}

/// Observable wrapper around MKLocalSearchCompleter, restricted to the
/// United States: the completer's region is a US bounding region and
/// the result type is addresses, so suggestions are real US places.
/// When the completer has no results (e.g. offline), the bundled
/// major-US-cities list fills in instead, so the field always
/// suggests certified US locations.
final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [String] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        // Bias completions to the United States (contiguous-US
        // bounding region). The app is US-only.
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 60))
    }

    /// Feed the field's text in; suggestions publish asynchronously.
    /// Under two characters there is nothing useful to suggest.
    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            suggestions = []
            return
        }
        completer.queryFragment = trimmed
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var seen = Set<String>()
        let mapped = completer.results.prefix(5).map {
            LocationSuggestions.displayText(title: $0.title, subtitle: $0.subtitle)
        }.filter { seen.insert($0).inserted }
        suggestions = mapped.isEmpty
            ? LocationSuggestions.matchingCities(query: completer.queryFragment)
            : mapped
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = LocationSuggestions.matchingCities(query: completer.queryFragment)
    }
}
