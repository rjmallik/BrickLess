import XCTest
import CoreLocation
@testable import PlayMatch

/// Away-from-home banner: the distance that counts as away, the
/// key that re-arms the banner, and where a banner tap goes home to.
final class AwayBannerTests: XCTestCase {

    func testDistanceMetersSanFranciscoToCupertinoIsFar() {
        // San Francisco to Cupertino (Apple HQ, the simulator's fake
        // fix) is roughly 50 km — well past the 25 km away threshold.
        let sf = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let cupertino = CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312)
        let distance = CityGeocoder.distanceMeters(from: sf, to: cupertino)
        XCTAssertGreaterThan(distance, 25_000)
        XCTAssertEqual(CityGeocoder.distanceMeters(from: sf, to: sf), 0, accuracy: 1)
    }

    func testAwayBannerKeyChangesWithCityAndArea() {
        let sf = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let cupertino = CLLocationCoordinate2D(latitude: 37.3318, longitude: -122.0312)
        let key = CityGeocoder.awayBannerKey(city: "San Francisco, CA", gps: cupertino)
        // A different city re-arms the banner.
        XCTAssertNotEqual(key, CityGeocoder.awayBannerKey(city: "Seattle, WA", gps: cupertino))
        // Moving to a new area re-arms it; staying in the same area does not.
        XCTAssertNotEqual(key, CityGeocoder.awayBannerKey(city: "San Francisco, CA", gps: sf))
        XCTAssertEqual(key, CityGeocoder.awayBannerKey(city: "San Francisco, CA", gps: cupertino))
    }

    func testBannerHomeTargetReturnsProfileCityCoordinate() {
        let sf = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let target = CityGeocoder.bannerHomeTarget(profileCityCoordinate: sf)
        XCTAssertEqual(target?.latitude, 37.7749)
        XCTAssertEqual(target?.longitude, -122.4194)
    }

    func testBannerHomeTargetReturnsNilWhenNoProfileCity() {
        XCTAssertNil(CityGeocoder.bannerHomeTarget(profileCityCoordinate: nil))
    }
}
