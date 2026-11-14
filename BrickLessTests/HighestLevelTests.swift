import XCTest
@testable import PlayMatch

/// Highest level officially played: the six levels, first/last, default.
final class HighestLevelTests: XCTestCase {

    func testHighestLevels() {
        XCTAssertEqual(UserProfile.highestLevels.first, "Recreational")
        XCTAssertEqual(UserProfile.highestLevels.last, "Professional")
        XCTAssertEqual(UserProfile.highestLevels.count, 6)
        XCTAssertEqual(UserProfile.defaultHighestLevel, "Recreational")
    }
}
