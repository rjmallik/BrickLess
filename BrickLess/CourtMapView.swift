import SwiftUI
import MapKit
import CoreLocation

/// "Find Games Near You": a map of courts and fields.
/// Courts and fields come from OpenStreetMap (free, global, but only
/// what volunteers mapped) plus community venues added by players.
/// Tap a pin to see the venue and book it. Apple Maps (MapKit) is the
/// map itself, so no Google Maps key or billing is needed for the map.
struct CourtMapView: View {
    @ObservedObject var session: SessionStore
    @StateObject private var store = CourtStore()
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
                           span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
    @State private var selectedCourt: Court?
    @State private var showingAddCourt = false
    /// Which sport tab is showing. All by default; a sport tab shows
    /// only that sport's courts, plus multi-sport pitches.
    @State private var selectedSport = SportTabs.allTag

    private var visibleCourts: [Court] {
        store.courts.filter { SportTabs.courtMatches($0, filter: selectedSport) }
    }

    /// Header for the selected sport: "All" shows every court and
    /// field; a sport tab names the sport and its venue word
    /// ("Basketball courts near you", "Soccer fields near you",
    /// "Table Tennis tables near you").
    private var headerTitle: String {
        selectedSport == SportTabs.allTag
            ? "Courts and fields near you"
            : "\(SportTabs.label(forTag: selectedSport)) \(Court.venueWordPlural(forSport: selectedSport)) near you"
    }

    /// The Add button: the venue word for the selected sport, or the
    /// generic "Add venue" on the All tab.
    private var addButtonLabel: String {
        selectedSport == SportTabs.allTag
            ? "Add venue"
            : "Add \(Court.venueWord(forSport: selectedSport))"
    }

    /// The loading line: the venue word for the selected sport, or the
    /// generic "venues" on the All tab.
    private var loadingText: String {
        selectedSport == SportTabs.allTag
            ? "Finding venues…"
            : "Finding \(Court.venueWordPlural(forSport: selectedSport))…"
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedCourt) {
                ForEach(visibleCourts) { court in
                    Annotation(court.name, coordinate: court.coordinate) {
                        let pin = SportTabs.pinStyle(forTag: court.sport)
                        Image(systemName: pin.symbol)
                            .font(.title2)
                            .padding(8)
                            .background(pin.color)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                    }
                    .tag(court)
                }
                if let location = locationManager.location {
                    Annotation("You", coordinate: location) {
                        Circle().fill(Color.blue).frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
            }
            .mapStyle(.standard)
            .onAppear {
                locationManager.requestPermission()
                store.fetchCourts(around: cameraPosition.region?.center
                    ?? CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321))
            }
            .onReceive(locationManager.$location) { location in
                // onChange can't watch CLLocationCoordinate2D: it is not
                // Equatable. onReceive on the @Published value needs no
                // Equatable conformance.
                guard let location else { return }
                cameraPosition = .region(MKCoordinateRegion(
                    center: location, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                store.fetchCourts(around: location)
            }

            // Header: what the map is centred on. When location is off
            // the map falls back to downtown Seattle, and says so instead
            // of pretending those are the courts near you.
            VStack(spacing: 4) {
                Text(headerTitle)
                    .font(.subheadline.bold())
                if locationManager.locationDenied && locationManager.location == nil {
                    Text("Location off — showing downtown Seattle. Enable location in Settings to see venues near you.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else if locationManager.location == nil {
                    Text("Finding your location…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                SportTabBar(selected: $selectedSport)
                    .padding(.top, 4)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding()

            // Re-centre on the user after panning away: one fresh fix,
            // which re-centres the map through the onReceive below.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if locationManager.location != nil {
                        Button {
                            locationManager.requestLocation()
                        } label: {
                            Image(systemName: "location.fill")
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Find Games Near You")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(addButtonLabel) { showingAddCourt = true }
            }
        }
        .sheet(item: $selectedCourt) { court in
            CourtDetailView(court: court, session: session)
        }
        .sheet(isPresented: $showingAddCourt) {
            AddCourtView(store: store, session: session,
                         coordinate: cameraPosition.region?.center
                            ?? CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
                         initialSport: selectedSport)
        }
        .overlay {
            if store.isLoading {
                ProgressView(loadingText).padding()
                    .background(.ultraThinMaterial).cornerRadius(10)
            }
        }
    }
}

private struct CourtDetailView: View {
    var court: Court
    @ObservedObject var session: SessionStore
    @State private var showingBooking = false
    @State private var showingEvents = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(court.name).font(.title2.bold())
            Text(Court.defaultName(forSport: court.sport))
                .foregroundColor(.secondary)
            if !court.surface.isEmpty { Text("Surface: \(court.surface)") }
            Text(court.lit ? "Lit for night games" : "Not marked as lit")
                .foregroundColor(.secondary)
            Text(court.indoor ? "Indoor" : "Outdoor")
                .foregroundColor(.secondary)
            // Verification: community venues are player-submitted and
            // start unverified (a pending request); OSM venues are
            // trusted public data. The paid booking link stays hidden
            // until a community venue is verified, so a fake venue
            // cannot carry a scam booking link.
            if court.source == "community" {
                if court.verified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.footnote).foregroundColor(.green)
                } else {
                    Label("Added by a player — pending verification", systemImage: "clock")
                        .font(.footnote).foregroundColor(.orange)
                }
            } else {
                Text("From OpenStreetMap — hours and availability are not listed")
                    .font(.footnote).foregroundColor(.secondary)
            }

            // Paid venue rental, via the venue's own booking site: the
            // player books and pays there; we take no payment in-app.
            // Only for indoor, verified venues that carry a booking
            // link. Outdoor and unverified venues never show it.
            if Court.canShowBookingLink(court),
               let bookingURL = Court.validatedBookingURL(court) {
                Link("Book this \(Court.venueWord(forSport: court.sport))", destination: bookingURL)
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(PlayMatchColors.brand).cornerRadius(8)
            }
            // In-app time reservation for a pickup game (free, no
            // payment). Separate from paid venue rental, so it is
            // labelled as a reservation, not a booking.
            Button("Reserve a time") { showingBooking = true }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                .background(SportTabs.pinStyle(forTag: court.sport).color).cornerRadius(8)
            Button("Post a game here") { showingEvents = true }
                .foregroundColor(SportTabs.pinStyle(forTag: court.sport).color)
                .frame(maxWidth: .infinity).padding()
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(SportTabs.pinStyle(forTag: court.sport).color, lineWidth: 1.5))
                .cornerRadius(8)
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingBooking) {
            BookingView(court: court, session: session)
        }
        .sheet(isPresented: $showingEvents) {
            NavigationView {
                EventsView(session: session, court: court)
            }
        }
    }
}

private struct AddCourtView: View {
    @ObservedObject var store: CourtStore
    @ObservedObject var session: SessionStore
    var coordinate: CLLocationCoordinate2D
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    /// The sport being added. Starts on the map's selected sport when
    /// it is a real sport, else basketball; the picker can change it.
    @State private var sport: String
    @State private var indoor = false
    /// Paid bookings: only offered for indoor venues. The link is the
    /// venue's own booking site, where players book and pay; we take no
    /// payment in-app. A new venue is unverified (pending review), so
    /// its link stays hidden until an admin verifies it.
    @State private var allowsBookings = false
    @State private var bookingURLText = ""
    @State private var errorMessage: String?

    init(store: CourtStore, session: SessionStore, coordinate: CLLocationCoordinate2D,
         initialSport: String = "basketball") {
        self.store = store
        self.session = session
        self.coordinate = coordinate
        _sport = State(initialValue: SportTabs.realSports.contains(initialSport)
                       ? initialSport : "basketball")
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Add a missing \(Court.venueWord(forSport: sport))").font(.title2.bold())
            Text("Dropped at the centre of your map. Other players will see it. New places are pending verification until we review them.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextField("Court or field name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Picker("Sport", selection: $sport) {
                // Court.sport tags, not the OSM query tags: the stored
                // sport must be a Court.sport value ("football", not
                // "american_football") or the sport filter and the
                // venue word will not recognise it.
                ForEach(SportTabs.sports) { sport in
                    Text(sport.label).tag(sport.tag)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Indoor", isOn: $indoor)
            if indoor {
                Toggle("Allows bookings", isOn: $allowsBookings)
                if allowsBookings {
                    TextField("Booking link (where players pay)", text: $bookingURLText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Text("Players will be sent to this link to book and pay. The venue stays pending verification until we review it.")
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
            if let errorMessage { Text(errorMessage).foregroundColor(.red) }
            Button("Add \(Court.venueWord(forSport: sport))") {
                guard let uid = session.firebaseUser?.uid else { return }
                // A booking link only counts for an indoor venue that
                // takes bookings, and it must be a real web link.
                let bookingLink: String?
                if indoor && allowsBookings {
                    let trimmed = bookingURLText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        errorMessage = "Add the booking link, or turn off Allows bookings."
                        return
                    }
                    guard Court.validatedBookingURLString(trimmed) != nil else {
                        errorMessage = "That booking link does not look like a web link — it should start with https://"
                        return
                    }
                    bookingLink = trimmed
                } else {
                    bookingLink = nil
                }
                let defaultName = Court.defaultName(forSport: sport)
                store.addCommunityCourt(name: name.isEmpty ? defaultName : name,
                                        sport: sport, coordinate: coordinate,
                                        surface: "", indoor: indoor, createdBy: uid,
                                        bookingURL: bookingLink) { error in
                    if let error { errorMessage = error } else { dismiss() }
                }
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding()
            .background(PlayMatchColors.brand).cornerRadius(8)
            Spacer()
        }
        .padding()
    }
}

/// Minimal location helper: asks once, then reports the user location.
/// Shared with profile setup, which offers the location prompt at signup.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    /// True when the user denied (or is restricted from) location access.
    /// The map shows a fallback and says so instead of silently
    /// pretending the fallback is the user's location.
    @Published var locationDenied = false
    /// Current authorization, so views can show the right state without
    /// asking again. Updated whenever iOS reports a change.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    /// What the profile-setup location step should show for a given
    /// authorization status. Pure so it is unit-testable without a device.
    /// - offerToEnable: the system prompt has never fired; show the button.
    /// - enabled: location is on; just say so.
    /// - unavailable: denied or restricted — iOS will not re-prompt, so
    ///   there is no button; the user can still finish signup.
    enum LocationSetupPrompt: Equatable {
        case offerToEnable
        case enabled
        case unavailable
    }

    static func setupPrompt(for status: CLAuthorizationStatus) -> LocationSetupPrompt {
        switch status {
        case .notDetermined:
            return .offerToEnable
        case .authorizedWhenInUse, .authorizedAlways:
            return .enabled
        case .denied, .restricted:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    /// One-shot fix, for the re-center button: delivers one location
    /// update, then stops on its own.
    func requestLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .denied, .restricted:
            locationDenied = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationDenied = false
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last?.coordinate
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // No fix (e.g. a simulator with no location set): keep the last
        // known location, or the Seattle fallback shown by the view.
    }
}
