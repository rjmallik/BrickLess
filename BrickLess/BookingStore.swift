import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

/// A booking is a reserved slot at a court, or a pickup game at one.
/// `bookings/{id}`: { courtId, courtName, sport, bookedBy, playerUids,
/// startTime, endTime, status: "confirmed" | "cancelled", createdAt }.
///
/// What booking means here, honestly:
/// - Reserving a slot / starting a pickup game in BrickLess: yes, fully.
/// - Booking a real facility that charges money: that only works where
///   the facility lets you book. Public parks mostly cannot be booked
///   through any API; private facilities have their own systems. Paid
///   bookings go through Stripe / Apple Pay, never Apple in-app purchase:
///   App Store Guideline 3.1.5(a) requires real-world services to be paid
///   outside IAP, and Apple takes no cut of them. A "Premium" subscription
///   that unlocks things inside the app is the opposite: that must use IAP.
struct Booking: Codable, Identifiable {
    @DocumentID var id: String?
    var courtId: String
    var courtName: String
    var sport: String
    var bookedBy: String
    var playerUids: [String]
    var startTime: Date
    var endTime: Date
    var status: String // confirmed, cancelled
    var createdAt: Date
}

class BookingStore: ObservableObject {
    @Published var myBookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit { listener?.remove() }

    /// Pure time check shared by bookCourt and the unit tests: two
    /// half-open ranges [start, end) overlap when each starts before
    /// the other ends. Back-to-back slots (one ends as the other
    /// starts) do not overlap.
    static func timeRangesOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        start1 < end2 && end1 > start2
    }

    /// True when any existing booking for the court overlaps the
    /// requested slot. Overlap is user-agnostic: a slot taken by
    /// another player blocks this one too.
    static func isCourtBooked(_ existing: [(start: Date, end: Date)], start: Date, end: Date) -> Bool {
        existing.contains {
            timeRangesOverlap(start1: $0.start, end1: $0.end, start2: start, end2: end)
        }
    }

    /// The two time guards in bookCourt, as a pure function (`now` is
    /// injected so tests can pin it).
    static func validateBookingTime(start: Date, end: Date, now: Date) -> String? {
        guard end > start else { return "End time must be after the start time." }
        guard start > now else { return "Pick a time in the future." }
        return nil
    }

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        listener = db.collection("bookings")
            .whereField("playerUids", arrayContains: uid)
            .whereField("status", isEqualTo: "confirmed")
            .order(by: "startTime")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.myBookings = snapshot?.documents.compactMap {
                    try? $0.data(as: Booking.self)
                } ?? []
            }
    }

    /// Books a slot. A court can only be booked once per overlapping time:
    /// the check below rejects a new booking that overlaps an existing
    /// confirmed one for the same court.
    func bookCourt(_ court: Court, start: Date, end: Date, playerUids: [String],
                   completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion("You are not signed in.")
            return
        }
        if let error = Self.validateBookingTime(start: start, end: end, now: Date()) {
            completion(error)
            return
        }
        isLoading = true
        db.collection("bookings")
            .whereField("courtId", isEqualTo: court.id)
            .whereField("status", isEqualTo: "confirmed")
            .whereField("startTime", isLessThan: end)
            .getDocuments { [weak self] snapshot, _ in
                guard let self else { return }
                let overlaps = snapshot?.documents.contains { doc in
                    guard let existingEnd = (doc.data()["endTime"] as? Timestamp)?.dateValue() else {
                        return false
                    }
                    // The query already filters startTime < end; the
                    // fallback only covers a doc missing startTime.
                    let existingStart = (doc.data()["startTime"] as? Timestamp)?.dateValue() ?? .distantPast
                    return Self.timeRangesOverlap(start1: existingStart, end1: existingEnd,
                                                  start2: start, end2: end)
                } ?? false
                guard !overlaps else {
                    self.isLoading = false
                    completion("That court is already booked for that time.")
                    return
                }
                var players = Set(playerUids)
                players.insert(uid)
                let booking = Booking(courtId: court.id, courtName: court.name,
                                      sport: court.sport, bookedBy: uid,
                                      playerUids: Array(players),
                                      startTime: start, endTime: end,
                                      status: "confirmed", createdAt: Date())
                do {
                    _ = try self.db.collection("bookings").addDocument(from: booking)
                    self.isLoading = false
                    completion(nil)
                } catch {
                    self.isLoading = false
                    completion(error.localizedDescription)
                }
            }
    }

    func cancelBooking(_ booking: Booking) {
        guard let id = booking.id else { return }
        db.collection("bookings").document(id).updateData(["status": "cancelled"])
    }
}
