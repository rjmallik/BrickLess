import SwiftUI

/// Book a court: pick a day, start time and length, invite friends.
/// The court is reserved in Firestore, and the booking shows in My Bookings.
struct BookingView: View {
    var court: Court
    @ObservedObject var session: SessionStore
    @StateObject private var bookingStore = BookingStore()
    @StateObject private var friendsStore = FriendsStore()
    @State private var date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var startTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var durationHours = 1
    @State private var invitedUids: Set<String> = []
    @State private var errorMessage: String?
    @State private var booked = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Book \(court.name)").font(.title2.bold())
            Text(court.sport == "soccer" ? "Soccer field" : "Basketball court")
                .foregroundColor(.secondary)

            DatePicker("Day", selection: $date, in: Date()..., displayedComponents: .date)
            DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
            Stepper("Length: \(durationHours) hour\(durationHours == 1 ? "" : "s")",
                    value: $durationHours, in: 1...4)

            if !friendsStore.friends.isEmpty {
                Text("Invite friends").font(.headline)
                ForEach(friendsStore.friends) { friend in
                    Toggle(friend.displayName, isOn: Binding(
                        get: { invitedUids.contains(friend.id ?? "") },
                        set: { on in
                            guard let id = friend.id else { return }
                            if on { invitedUids.insert(id) } else { invitedUids.remove(id) }
                        }
                    ))
                }
            }

            if let errorMessage { Text(errorMessage).foregroundColor(.red) }
            if booked {
                Text("Booked. It is in My Bookings.")
                    .foregroundColor(.green).font(.headline)
            }

            if bookingStore.isLoading {
                ProgressView().padding()
            } else if !booked {
                Button("Confirm booking") {
                    errorMessage = nil
                    let calendar = Calendar.current
                    let day = calendar.dateComponents([.year, .month, .day], from: date)
                    let time = calendar.dateComponents([.hour, .minute], from: startTime)
                    var startComponents = DateComponents()
                    startComponents.year = day.year
                    startComponents.month = day.month
                    startComponents.day = day.day
                    startComponents.hour = time.hour
                    startComponents.minute = time.minute
                    guard let start = calendar.date(from: startComponents),
                          let end = calendar.date(byAdding: .hour, value: durationHours, to: start) else {
                        errorMessage = "Pick a valid time."
                        return
                    }
                    bookingStore.bookCourt(court, start: start, end: end,
                                           playerUids: Array(invitedUids)) { error in
                        if let error { errorMessage = error } else { booked = true }
                    }
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                .background(Color.blue).cornerRadius(8)
            }

            Button("Done") { dismiss() }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
        .onAppear {
            friendsStore.startListening()
            bookingStore.startListening()
        }
    }
}

/// The signed-in user's upcoming bookings, linked from My Profile.
struct MyBookingsView: View {
    @StateObject private var store = BookingStore()

    var body: some View {
        List {
            if store.myBookings.isEmpty {
                Text("No upcoming bookings. Find a court on the map and book it.")
                    .foregroundColor(.secondary)
            }
            ForEach(store.myBookings) { booking in
                VStack(alignment: .leading) {
                    Text(booking.courtName).font(.headline)
                    Text("\(booking.startTime.formatted(date: .abbreviated, time: .shortened)) – \(booking.endTime.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("\(booking.playerUids.count) player\(booking.playerUids.count == 1 ? "" : "s")")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .swipeActions {
                    Button("Cancel", role: .destructive) {
                        store.cancelBooking(booking)
                    }
                }
            }
        }
        .navigationTitle("My Bookings")
        .onAppear { store.startListening() }
    }
}
