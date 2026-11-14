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
    /// Geocodes the profile city (cached per city string) so the map
    /// can centre on it. The profile city is the player's preferred /
    /// home location; the map follows it when one is set.
    @StateObject private var cityGeocoder = CityGeocoder()
    /// The geocoded coordinate of the profile city the map is
    /// currently centred on, if any.
    @State private var profileCityCoordinate: CLLocationCoordinate2D?
    /// The city string profileCityCoordinate was geocoded from, so a
    /// city is only geocoded once.
    @State private var lastCenteredCity: String?
    /// The re-centre button was tapped: the next GPS fix jumps the
    /// map to the live location even when a profile city is set.
    @State private var recenterRequested = false
    /// The away-banner dismissal key (profile city + coarse GPS area)
    /// the player last dismissed with the X. The banner stays hidden
    /// for that city-and-area, and re-arms when the city changes or
    /// the player moves to a new area.
    @State private var awayBannerDismissedFor: String?
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

    /// Whether the "away from home" banner shows: the player has a
    /// profile city (geocoded) and a live GPS fix, the fix is farther
    /// than the away threshold from the profile city, and the player
    /// has not dismissed it for this city-and-area with the X.
    /// The banner is only a notice — it never moves the map.
    private var showAwayBanner: Bool {
        guard let cityCoord = profileCityCoordinate,
              let gps = locationManager.location,
              let city = session.profile?.city,
              !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard CityGeocoder.distanceMeters(from: cityCoord, to: gps)
                > CityGeocoder.awayThresholdMeters else { return false }
        return awayBannerDismissedFor != CityGeocoder.awayBannerKey(city: city, gps: gps)
    }

    /// Center the map and fetch venues: the profile city wins when
    /// set (geocoded, cached); otherwise the current centre (GPS fix
    /// when one arrives, else the Seattle default).
    private func refreshCenter() {
        if CityGeocoder.centerChoice(profileCity: session.profile?.city,
                                     hasGPSFix: locationManager.location != nil) == .profileCity {
            centerOnProfileCityIfNeeded()
        } else {
            store.fetchCourts(around: cameraPosition.region?.center
                ?? CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321))
        }
    }

    /// Centre the map on the signed-in player's profile city when one
    /// is set. The profile city wins over the GPS fix: that is the
    /// point — a player who sets their city sees venues there even
    /// when the device GPS is somewhere else (e.g. the simulator's
    /// fake Cupertino fix). No city set means the current behaviour
    /// (GPS fix when available, else the Seattle default).
    private func centerOnProfileCityIfNeeded() {
        guard let rawCity = session.profile?.city,
              !rawCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // No profile city: clear any profile-city centre so the
            // GPS fix (or the Seattle default) takes over again.
            profileCityCoordinate = nil
            lastCenteredCity = nil
            return
        }
        let key = CityGeocoder.normalizedCity(rawCity)
        guard key != lastCenteredCity else { return }
        cityGeocoder.coordinate(for: rawCity) { coordinate in
            // The city may have changed while geocoding; only apply a
            // result that still matches the current profile city.
            guard CityGeocoder.normalizedCity(session.profile?.city ?? "") == key else { return }
            guard let coordinate else { return } // geocode failed: stay put
            profileCityCoordinate = coordinate
            lastCenteredCity = key
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
            store.fetchCourts(around: coordinate)
        }
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
                // The player's own location, made unmistakable: the
                // native blue user-location dot, plus a "You are here"
                // label floating above it, so the player can always
                // tell where they are on the map — even when the map
                // is centred on their profile city rather than on GPS.
                UserAnnotation()
                if let location = locationManager.location {
                    Annotation("You are here", coordinate: location) {
                        Text("You are here")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 3)
                            .offset(y: -30)
                    }
                }
            }
            .mapStyle(.standard)
            .onAppear {
                locationManager.requestPermission()
                refreshCenter()
            }
            .onChange(of: session.profile?.city) {
                // The profile city was saved or changed (including the
                // first load after sign-in): re-centre the map on it.
                refreshCenter()
            }
            .onReceive(locationManager.$location) { location in
                // onChange can't watch CLLocationCoordinate2D: it is not
                // Equatable. onReceive on the @Published value needs no
                // Equatable conformance.
                guard let location else { return }
                // A profile city drives the map when one is set, so a
                // GPS fix must not yank the centre away (the
                // simulator's fake fix would win otherwise). The
                // re-centre button is the exception: an explicit tap
                // always jumps to the live GPS fix.
                if !recenterRequested,
                   CityGeocoder.centerChoice(profileCity: session.profile?.city,
                                             hasGPSFix: true) == .profileCity {
                    return
                }
                recenterRequested = false
                cameraPosition = .region(MKCoordinateRegion(
                    center: location, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
                store.fetchCourts(around: location)
            }

            // Header: what the map is centred on. When location is off
            // the map falls back to downtown Seattle, and says so instead
            // of pretending those are the courts near you.
            VStack(spacing: 8) {
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

                // Away from home: the player's live GPS is far from
                // their profile city (the preferred/home location).
                // Just a notice — it never moves the map. The X on
                // the right dismisses it; dismissing means keep
                // looking around here (the profile city).
                if showAwayBanner, let city = session.profile?.city {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(PlayMatchColors.brand)
                        Text("You're away from \(city). Still looking around here?")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            if let gps = locationManager.location {
                                awayBannerDismissedFor = CityGeocoder.awayBannerKey(city: city, gps: gps)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.bold())
                                .foregroundColor(.secondary)
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
            }
            .padding()

            // Re-centre on the user after panning away: one fresh fix,
            // which re-centres the map through the onReceive below.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if locationManager.location != nil {
                        Button {
                            recenterRequested = true
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
                SportyLoadingView()
            }
        }
    }
}

/// The venue loading cycle: which sports ball shows, and whether
/// the line reads "Finding…" or "Loading…", at each second of a
/// venue fetch. Pure so it is unit-testable.
enum VenueLoadingCycle {
    /// The sports whose ball icons cycle while loading, in order.
    static let tags = ["basketball", "soccer", "football", "tennis",
                       "pickleball", "table_tennis", "golf"]

    /// The sport tag whose ball icon shows at a cycle step.
    static func tag(at index: Int) -> String {
        tags[index % tags.count]
    }

    /// The loading line at a cycle step: "Finding…" on even steps,
    /// "Loading…" on odd steps.
    static func text(at index: Int) -> String {
        index.isMultiple(of: 2) ? "Finding…" : "Loading…"
    }
}

/// Playful venue loading state: the text alternates between
/// "Finding…" and "Loading…" and a sports ball spins, cycling
/// through the sports once a second, so a slow venue fetch still
/// feels alive. Shown while the court store is loading.
private struct SportyLoadingView: View {
    @State private var index = 0
    @State private var rotation: Double = 0

    private var style: (symbol: String, color: Color) {
        SportTabs.pinStyle(forTag: VenueLoadingCycle.tag(at: index))
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.symbol)
                .font(.title2)
                .foregroundColor(style.color)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            Text(VenueLoadingCycle.text(at: index))
                .font(.subheadline.bold())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            index += 1
        }
    }
}

/// Which centre the map should use. Pure so it is unit-testable.
enum MapCenterChoice: Equatable {
    /// The profile city (geocoded) — the player's preferred/home location.
    case profileCity
    /// The live GPS fix.
    case gps
    /// The Seattle fallback (no city, no fix).
    case seattle
}

/// Geocodes a profile city to a coordinate, caching results per city
/// string so the map does not re-geocode on every appearance.
/// CLGeocoder is rate-limited, so one lookup per distinct city.
final class CityGeocoder: ObservableObject {
    /// "Away" means the live GPS fix is farther than this from the
    /// geocoded profile city. Matches the venue search radius (25 km).
    static let awayThresholdMeters: Double = 25_000

    private var cache: [String: CLLocationCoordinate2D] = [:]
    private let geocoder = CLGeocoder()

    /// Cache key for a city string: trimmed and lowercased, so
    /// "Seattle" and "seattle " share one lookup. Pure.
    static func normalizedCity(_ city: String) -> String {
        city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Which centre the map should use, given the profile city and
    /// whether a GPS fix exists. The profile city wins when set
    /// (that is the point: the map follows the city the player
    /// chose); GPS is next; Seattle is the fallback. Pure.
    static func centerChoice(profileCity: String?, hasGPSFix: Bool) -> MapCenterChoice {
        if let city = profileCity, !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .profileCity
        }
        return hasGPSFix ? .gps : .seattle
    }

    /// Straight-line distance between two coordinates, in metres. Pure.
    static func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    /// The dismissal key for the away banner: the profile city plus a
    /// coarse (~11 km) cell of the live GPS fix, so moving to a new
    /// area or changing the profile city re-arms the banner. Pure.
    static func awayBannerKey(city: String, gps: CLLocationCoordinate2D) -> String {
        "\(normalizedCity(city))|\(Int(gps.latitude * 10))_\(Int(gps.longitude * 10))"
    }

    /// Geocode a city to a coordinate. A cached city answers
    /// instantly; a new city goes through CLGeocoder once, then is
    /// cached. Completion always runs on the main thread.
    func coordinate(for city: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let key = Self.normalizedCity(city)
        if let cached = cache[key] {
            completion(cached)
            return
        }
        guard !key.isEmpty else {
            completion(nil)
            return
        }
        // One lookup at a time: a new request cancels an in-flight
        // one, and the cancelled completion reports no coordinate.
        geocoder.cancelGeocode()
        geocoder.geocodeAddressString(city) { [weak self] placemarks, _ in
            let coordinate = placemarks?.first?.location?.coordinate
            if let coordinate {
                self?.cache[key] = coordinate
            }
            DispatchQueue.main.async { completion(coordinate) }
        }
    }
}

private struct CourtDetailView: View {
    var court: Court
    @ObservedObject var session: SessionStore
    @State private var showingBooking = false

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
            // Post a game at this venue (free, no payment): pick a
            // time for a pickup game here. Separate from paid venue
            // rental above, so it is labelled as posting a game,
            // not a booking.
            Button("Post a game") { showingBooking = true }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                .background(SportTabs.pinStyle(forTag: court.sport).color).cornerRadius(8)
            Spacer()
        }
        .padding()
        .appBackground()
        .sheet(isPresented: $showingBooking) {
            BookingView(court: court, session: session)
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
