import SwiftUI

/// Upcoming pickup games: anyone can post one at a court, and anyone
/// signed in can see the list and join. Overlapping games at the same
/// court are fine — these are pickup games, not reservations.
struct EventsView: View {
    @ObservedObject var session: SessionStore
    var court: Court? = nil // when opened from a court, new games default to it
    @StateObject private var store = EventStore()
    @State private var showingCreate = false
    @State private var showingMineOnly = false

    private var shownEvents: [GameEvent] {
        if showingMineOnly {
            // My games: joined events that have not started yet.
            store.myEvents.filter { $0.startTime > Date() }
        } else {
            store.upcomingEvents
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Games", selection: $showingMineOnly) {
                Text("All games").tag(false)
                Text("My games").tag(true)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                if shownEvents.isEmpty {
                    Text(showingMineOnly
                         ? "You have not joined any games yet."
                         : "No upcoming games. Be the first to post one.")
                        .foregroundColor(.secondary)
                }
                ForEach(shownEvents) { event in
                    NavigationLink(destination: EventDetailView(event: event, session: session)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title).font(.headline)
                            Text(event.courtName).font(.subheadline)
                            Text("\(event.startTime.formatted(date: .abbreviated, time: .shortened)) – \(event.endTime.formatted(date: .omitted, time: .shortened))")
                                .font(.subheadline).foregroundColor(.secondary)
                            Text("\(event.playerUids.count)/\(event.maxPlayers) players · Hosted by \(event.creatorUsername)")
                                .font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Games")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Game") { showingCreate = true }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateEventForm(store: store, session: session, court: court)
        }
        .onAppear {
            store.startListeningUpcoming()
            store.startListeningMyEvents()
        }
        .onDisappear {
            store.stopListening()
        }
    }
}

/// The create-event form: pick a court (passed in, or type a name),
/// title, date/time, max players, description.
struct CreateEventForm: View {
    @ObservedObject var store: EventStore
    @ObservedObject var session: SessionStore
    var court: Court?

    @State private var title = ""
    @State private var courtName = ""
    @State private var start = Self.defaultStart()
    @State private var end = Self.defaultEnd()
    @State private var maxPlayers = 10
    @State private var description = ""
    @State private var errorMessage: String?
    @State private var created = false
    @Environment(\.dismiss) private var dismiss

    /// Tomorrow at 6pm, like the booking form's default.
    private static func defaultStart() -> Date {
        let calendar = Calendar.current
        let sixPm = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        return calendar.date(byAdding: .day, value: 1, to: sixPm) ?? sixPm
    }

    private static func defaultEnd() -> Date {
        defaultStart().addingTimeInterval(2 * 60 * 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Title (e.g. Sunday run)", text: $title)
                    if let court {
                        HStack {
                            Text("Court")
                            Spacer()
                            Text(court.name).foregroundColor(.secondary)
                        }
                    } else {
                        TextField("Court name", text: $courtName)
                    }
                    TextField("Details (optional)", text: $description, axis: .vertical)
                }

                Section("When") {
                    DatePicker("Starts", selection: $start, in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Ends", selection: $end, in: start...,
                               displayedComponents: [.date, .hourAndMinute])
                }

                Section("Players") {
                    Stepper("Max players: \(maxPlayers)", value: $maxPlayers, in: 2...30)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
                if created {
                    Text("Game posted. It is in the list.")
                        .foregroundColor(.green).font(.headline)
                }

                if store.isLoading {
                    ProgressView().padding()
                } else if !created {
                    Button("Post game") {
                        errorMessage = nil
                        guard let username = session.profile?.username, !username.isEmpty else {
                            errorMessage = "Finish your profile first."
                            return
                        }
                        store.isLoading = true
                        store.createEvent(court: court, courtName: courtName, title: title,
                                          start: start, end: end, maxPlayers: maxPlayers,
                                          description: description,
                                          creatorUsername: username) { error in
                            store.isLoading = false
                            if let error {
                                errorMessage = error
                            } else {
                                created = true
                            }
                        }
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).cornerRadius(8)
                }

                Button("Done") { dismiss() }
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("New Game")
            .onChange(of: start) {
                // Keep the end after the start when the start moves.
                if end <= start {
                    end = start.addingTimeInterval(2 * 60 * 60)
                }
            }
        }
    }
}
