import Foundation
import FirebaseFirestoreSwift

/// A BrickLess player's public profile, stored in Firestore at `users/{uid}`.
/// Usernames are unique: each one is also reserved in `usernames/{lowercasedUsername}`
/// with `{ uid, email }`, so a username lookup is a single document read.
struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String          // display form, e.g. "RJHoops"
    var usernameLower: String     // lowercased, used as the `usernames/` doc id
    var email: String
    var displayName: String
    var position: String          // Point Guard, Shooting Guard, Small Forward, Power Forward, Center, Any
    var skillLevel: String        // Beginner, Intermediate, Advanced, Pro
    var city: String              // optional, free text
    var sports: [String] = []     // picked at signup: Basketball, Soccer, Football
    var profileComplete: Bool = false // false until Save Profile is tapped
    // How good the player is. All three are Optional with a nil default
    // so older profile documents that lack them still decode: Swift's
    // synthesized Codable throws on a missing non-optional key.
    var age: Int? = nil            // years
    var heightInches: Int? = nil   // total inches, e.g. 74 for 6'2"
    var highestLevel: String? = nil // highest level officially played
    var createdAt: Date
    var updatedAt: Date

    static let positions = ["Any", "Point Guard", "Shooting Guard", "Small Forward", "Power Forward", "Center"]
    static let skillLevels = ["Beginner", "Intermediate", "Advanced", "Pro"]

    /// Highest level officially played, in ascending order. New profiles
    /// default to Recreational at setup; older profiles may not have one.
    static let highestLevels = ["Recreational", "Middle School", "High School",
                                "College", "Semi-Pro", "Professional"]
    static let defaultHighestLevel = "Recreational"

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
    // Sports offered at signup. Launch is basketball only; add "Soccer"
    // then "Football" here to expand, in that order. CourtStore's
    // launchSports is the matching list for the map.
    static let allSports = ["Basketball"]

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
