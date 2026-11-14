import XCTest
import UIKit
@testable import PlayMatch

/// Profile photos: per-user storage path, the 1024px resize rule,
/// the optional photo URL (nil by default, round-trips through
/// Codable), and JPEG encoding of the picked image.
final class ProfilePhotoTests: XCTestCase {

    func testPhotoStoragePathIsPerUser() {
        XCTAssertEqual(UserProfile.photoStoragePath(for: "uid-1"), "profilePhotos/uid-1.jpg")
        XCTAssertEqual(UserProfile.photoStoragePath(for: "VMBNO9hbAQYtOF9W1jRbihxTqzt1"),
                       "profilePhotos/VMBNO9hbAQYtOF9W1jRbihxTqzt1.jpg")
    }

    func testScaledPhotoSizeCapsLongestSide() {
        // Landscape: longest side capped at 1024, aspect kept.
        XCTAssertEqual(UserProfile.scaledPhotoSize(for: CGSize(width: 2000, height: 1000), maxDimension: 1024),
                       CGSize(width: 1024, height: 512))
        // Portrait: the height is the longest side.
        XCTAssertEqual(UserProfile.scaledPhotoSize(for: CGSize(width: 500, height: 2000), maxDimension: 1024),
                       CGSize(width: 256, height: 1024))
        // Square.
        XCTAssertEqual(UserProfile.scaledPhotoSize(for: CGSize(width: 2048, height: 2048), maxDimension: 1024),
                       CGSize(width: 1024, height: 1024))
    }

    func testScaledPhotoSizeNeverScalesUp() {
        XCTAssertEqual(UserProfile.scaledPhotoSize(for: CGSize(width: 800, height: 600), maxDimension: 1024),
                       CGSize(width: 800, height: 600))
        XCTAssertEqual(UserProfile.scaledPhotoSize(for: CGSize(width: 1024, height: 768), maxDimension: 1024),
                       CGSize(width: 1024, height: 768))
    }

    func testPhotoURLDefaultsToNil() {
        XCTAssertNil(makeProfile().photoURL)
    }

    func testPhotoURLRoundTripsThroughCodable() throws {
        var profile = makeProfile()
        profile.photoURL = "https://example.com/profilePhotos/uid-1.jpg"
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
        XCTAssertEqual(decoded.photoURL, "https://example.com/profilePhotos/uid-1.jpg")
    }

    func testProfileWithoutPhotoURLStillDecodes() throws {
        // Older profile documents have no photoURL key; they must still
        // decode, with the photo nil.
        let json = """
        {"id":"uid-1","username":"rjhoops","usernameLower":"rjhoops","displayName":"rjhoops",
         "position":"Any","skillLevel":"Beginner","city":"","sports":["Basketball"],
         "sportProfiles":[],"profileComplete":true,
         "createdAt":1800000000,"updatedAt":1800000000}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(UserProfile.self, from: json)
        XCTAssertNil(decoded.photoURL)
        XCTAssertEqual(decoded.username, "rjhoops")
    }

    func testPhotoJPEGDataIsJPEG() {
        // A solid-color image encodes to JPEG data (starts with FF D8).
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let data = SessionStore.photoJPEGData(for: image)
        XCTAssertNotNil(data)
        if let data {
            XCTAssertEqual([UInt8](data.prefix(2)), [0xFF, 0xD8])
        }
    }
}
