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
        guard end > start else {
            completion("End time must be after the start time.")
            return
        }
        guard start > Date() else {
            completion("Pick a time in the future.")
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
                    return existingEnd > start
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
