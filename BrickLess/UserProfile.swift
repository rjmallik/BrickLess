import Foundation
import FirebaseFirestoreSwift

/// A PlayMatch player's public profile, stored in Firestore at `users/{uid}`.
/// Usernames are unique: each one is also reserved in `usernames/{lowercasedUsername}`
/// with `{ uid }` only. The profile and the username reservation hold no
/// private contact details: the email lives in Firebase Auth only, never
/// in a Firestore document another user could read.
/// One sport a player plays, with the positions, skill level and
/// highest level for that sport only. A player opts in to the sports
/// they play at profile setup, and each sport gets its own section:
/// positions are per-sport (a basketball point guard is not a soccer
/// goalkeeper), the skill level is per-sport, and the highest level
/// played is per-sport and optional (nil = not specified).
struct SportProfile: Codable, Equatable {
    var sport: String              // display name, e.g. "Basketball"
    var positions: [String]        // positions for this sport, multi-select
    var skillLevel: String         // Beginner, Intermediate, Advanced, Pro
    var highestLevel: String?      // highest level played, nil = not specified
}

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String          // display form, e.g. "RJHoops"
    var usernameLower: String     // lowercased, used as the `usernames/` doc id
    var displayName: String
    /// Primary sport's position and skill level, derived on save from the
    /// first opted-in sport. They are what the player lists show
    /// ("@rjhoops · Point Guard"). The full per-sport detail lives in
    /// sportProfiles below.
    var position: String          // primary sport's first position, or "Any"
    var skillLevel: String        // primary sport's skill level
    var city: String              // optional, free text
    /// Sports the player opted in to at profile setup. All phases except
    /// golf (phase 4): basketball, soccer, American football, tennis,
    /// pickleball, table tennis.
    var sports: [String] = []
    /// Per-sport detail, one entry per opted-in sport. The source of
    /// truth for positions, skill level and highest level.
    var sportProfiles: [SportProfile] = []
    var profileComplete: Bool = false // false until Save Profile is tapped
    // How good the player is. All three are Optional with a nil default
    // so older profile documents that lack them still decode: Swift's
    // synthesized Codable throws on a missing non-optional key.
    var age: Int? = nil            // years
    var heightInches: Int? = nil   // total inches, e.g. 74 for 6'2"
    /// Highest level played across ALL the player's sports (the max of
    /// the per-sport highest levels). This is what the Players level
    /// filter queries server-side, so it stays a single top-level field.
    /// Nil when the player did not specify a highest level for any sport.
    var highestLevel: String? = nil // highest level officially played
    var createdAt: Date
    var updatedAt: Date

    static let positions = ["Any", "Point Guard", "Shooting Guard", "Small Forward", "Power Forward", "Center"]
    static let soccerPositions = ["Any", "Goalkeeper", "Defender", "Midfielder", "Forward"]
    static let americanFootballPositions = ["Any", "Quarterback", "Running Back", "Wide Receiver", "Tight End", "Offensive Line", "Defensive Line", "Linebacker", "Defensive Back", "Kicker"]
    /// Racket sports have no field positions: the choice is the format.
    static let racketPositions = ["Any", "Singles", "Doubles"]

    /// Positions for a sport, by its display name. Basketball keeps the
    /// original list; racket sports offer Singles / Doubles instead.
    static func positions(forSport sport: String) -> [String] {
        switch sport {
        case "Soccer": return soccerPositions
        case "American Football": return americanFootballPositions
        case "Tennis", "Pickleball", "Table Tennis": return racketPositions
        default: return positions
        }
    }

    static let skillLevels = ["Beginner", "Intermediate", "Advanced", "Pro"]

    /// Highest level officially played, in ascending order. New profiles
    /// default to Recreational at setup; older profiles may not have one.
    static let highestLevels = ["Recreational", "Middle School", "High School",
                                "College", "Semi-Pro", "Professional"]
    static let defaultHighestLevel = "Recreational"

    /// The player's overall highest level: the max of the per-sport
    /// highest levels, by the ordering above. Nil when no sport has one
    /// specified. Pure so it is unit-testable.
    static func overallHighestLevel(from sportProfiles: [SportProfile]) -> String? {
        let levels = sportProfiles.compactMap(\.highestLevel)
        return levels.max { a, b in
            (highestLevels.firstIndex(of: a) ?? -1) < (highestLevels.firstIndex(of: b) ?? -1)
        }
    }

    /// The primary sport profile: the first opted-in sport, in allSports
    /// order. Its position and skill level are what the top-level
    /// `position` / `skillLevel` fields carry.
    static func primarySportProfile(from sportProfiles: [SportProfile]) -> SportProfile? {
        allSports.compactMap { name in sportProfiles.first { $0.sport == name } }.first
    }

    /// Age must be 13-100. The app is not directed at children under 13.
    static let ageRange = 13...100

    /// Feet range for the height picker (3'0" to 8'11").
    static let heightFeetRange = 3...8

    /// Total inches (e.g. 74) as "6'2\"".
    static func formattedHeight(_ inches: Int) -> String {
        "\(inches / 12)'\(inches % 12)\""
    }

    /// This profile's height as "6'2\"", or nil when not provided.
    var heightFormatted: String? {
        heightInches.map { Self.formattedHeight($0) }
    }
    // Sports offered at signup. All phases except golf (phase 4):
    // basketball (phase 1), soccer + American football (phase 2),
    // tennis + pickleball + table tennis (phase 3). CourtStore's
    // launchSports is the matching list for the map, in OSM tag form.
    static let allSports = ["Basketball", "Soccer", "American Football",
                            "Tennis", "Pickleball", "Table Tennis"]

    /// Username rules shared by signup and profile editing.
    /// 3-20 chars, letters, numbers and underscores only.
    static func isValidUsername(_ username: String) -> Bool {
        guard username.count >= 3, username.count <= 20 else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        return username.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// Small denylist for usernames and display names (Guideline 1.2:
    /// filter objectionable material before it is posted). This is a
    /// first pass, not a full filter; reporting and blocking cover the rest.
    static let blockedWords: Set<String> = [
        "fuck", "shit", "bitch", "cunt", "dick", "pussy",
        "whore", "slut", "nigger", "faggot"
    ]

    static func containsBlockedWord(_ text: String) -> Bool {
        let lower = text.lowercased()
        return blockedWords.contains { lower.contains($0) }
    }

    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("@"), trimmed.contains(".") else { return false }
        let parts = trimmed.split(separator: "@")
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return false }
        return parts[1].contains(".")
    }

    /// Parses the optional age field from profile setup: blank means
    /// "not provided", a number in 13...100 is valid, anything else is
    /// invalid. Mirrors the setup screen, which uses plain Int(text)
    /// (no whitespace trimming), so " 25" is invalid.
    enum AgeInput: Equatable {
        case blank
        case valid(Int)
        case invalid
    }

    static func parseAge(_ text: String) -> AgeInput {
        if text.trimmingCharacters(in: .whitespaces).isEmpty { return .blank }
        if let parsed = Int(text), ageRange.contains(parsed) { return .valid(parsed) }
        return .invalid
    }
}
