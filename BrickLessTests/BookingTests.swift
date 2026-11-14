import XCTest
@testable import PlayMatch

/// Court bookings: time validation and the overlap check that stops
/// two players booking the same court at the same time.
final class BookingTests: XCTestCase {

    private func hour(_ offset: TimeInterval) -> Date {
        testNow.addingTimeInterval(offset)
    }

    // MARK: - Overlap

    func testOverlappingRanges() {
        XCTAssertTrue(BookingStore.timeRangesOverlap(start1: hour(0), end1: hour(3600), start2: hour(1800), end2: hour(5400)))
        XCTAssertTrue(BookingStore.timeRangesOverlap(start1: hour(0), end1: hour(7200), start2: hour(1800), end2: hour(3600))) // contained
        XCTAssertTrue(BookingStore.timeRangesOverlap(start1: hour(1800), end1: hour(3600), start2: hour(0), end2: hour(7200))) // containing
        XCTAssertTrue(BookingStore.timeRangesOverlap(start1: hour(0), end1: hour(3600), start2: hour(0), end2: hour(3600))) // identical
    }

    func testBackToBackAndDisjointRangesDoNotOverlap() {
        XCTAssertFalse(BookingStore.timeRangesOverlap(start1: hour(0), end1: hour(3600), start2: hour(3600), end2: hour(7200)))
        XCTAssertFalse(BookingStore.timeRangesOverlap(start1: hour(3600), end1: hour(7200), start2: hour(0), end2: hour(3600)))
        XCTAssertFalse(BookingStore.timeRangesOverlap(start1: hour(0), end1: hour(3600), start2: hour(7200), end2: hour(10800)))
    }

    // MARK: - Court availability across users

    func testCourtBookedWhenAnotherPlayerHoldsAnOverlappingSlot() {
        let existing = [(start: hour(0), end: hour(3600))]
        XCTAssertTrue(BookingStore.isCourtBooked(existing, start: hour(1800), end: hour(5400)))
    }

    func testCourtFreeForBackToBackAndNonOverlappingSlots() {
        let existing = [(start: hour(0), end: hour(3600))]
        XCTAssertFalse(BookingStore.isCourtBooked(existing, start: hour(3600), end: hour(7200)))
        XCTAssertFalse(BookingStore.isCourtBooked(existing, start: hour(-3600), end: hour(0)))
    }

    func testCourtBookedWhenAnyExistingBookingOverlaps() {
        let existing = [(start: hour(0), end: hour(3600)), (start: hour(7200), end: hour(10800))]
        XCTAssertTrue(BookingStore.isCourtBooked(existing, start: hour(9000), end: hour(12600)))
        XCTAssertFalse(BookingStore.isCourtBooked(existing, start: hour(3600), end: hour(7200)))
    }

    func testCourtFreeWithNoExistingBookings() {
        XCTAssertFalse(BookingStore.isCourtBooked([], start: hour(0), end: hour(3600)))
    }

    // MARK: - Time validation

    func testValidBookingTimePasses() {
        XCTAssertNil(BookingStore.validateBookingTime(start: hour(3600), end: hour(7200), now: testNow))
    }

    func testBookingRejectsEndBeforeStart() {
        XCTAssertEqual(BookingStore.validateBookingTime(start: hour(7200), end: hour(3600), now: testNow),
                       "End time must be after the start time.")
        XCTAssertEqual(BookingStore.validateBookingTime(start: hour(3600), end: hour(3600), now: testNow),
                       "End time must be after the start time.")
    }

    func testBookingRejectsPastStart() {
        XCTAssertEqual(BookingStore.validateBookingTime(start: hour(-3600), end: hour(3600), now: testNow),
                       "Pick a time in the future.")
    }

    func testBookingTimeCheckOrder() {
        // End before start wins over a past start: checks run in order.
        XCTAssertEqual(BookingStore.validateBookingTime(start: hour(-7200), end: hour(-10800), now: testNow),
                       "End time must be after the start time.")
    }
}
