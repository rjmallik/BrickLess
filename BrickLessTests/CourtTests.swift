import XCTest
import CoreLocation
@testable import PlayMatch

/// Court map: grid cells for the geo-scoped fetch (~1 km cells).
final class CourtTests: XCTestCase {

    func testGridKeyForSeattle() {
        // Downtown Seattle, matching the doc comment on Court.gridKey.
        XCTAssertEqual(Court.gridKey(latitude: 47.6062, longitude: -122.3321), "4760_-12233")
    }

    func testGridKeyAtOriginAndSouthernHemisphere() {
        XCTAssertEqual(Court.gridKey(latitude: 0, longitude: 0), "0_0")
        XCTAssertEqual(Court.gridKey(latitude: -33.8688, longitude: 151.2093), "-3386_15120")
    }

    func testNearbyGridKeysCoverCenterAndNeighbours() {
        let keys = Court.nearbyGridKeys(around: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321))
        XCTAssertEqual(keys.count, 9)
        XCTAssertEqual(Set(keys).count, 9) // all distinct
        XCTAssertTrue(keys.contains("4760_-12233")) // the center cell
        XCTAssertTrue(keys.contains("4761_-12232"))
        XCTAssertTrue(keys.contains("4759_-12234"))
    }
}
