import SwiftUI
import MapKit
import CoreLocation

/// "Find Games Near You": a map of basketball courts and soccer fields.
/// Courts come from OpenStreetMap (free, global, but only what volunteers
/// mapped) plus community courts added by players. Tap a pin to see the
/// court and book it. Apple Maps (MapKit) is the map itself, so no
/// Google Maps key or billing is needed for the map.
struct CourtMapView: View {
    @ObservedObject var session: SessionStore
    @StateObject private var store = CourtStore()
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
                           span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)))
    @State private var selectedCourt: Court?
    @State private var showingAddCourt = false

    // Launch is basketball only, so there is no sport filter yet.
    // When soccer is added, this becomes a filter over the launch sports.
    private var visibleCourts: [Court] {
        store.courts
    }

    /// Pin icon and colour per sport. "figure.american.football" is an
    /// SF Symbol available since iOS 16.
    private func pinIcon(for sport: String) -> (String, Color) {
        switch sport {
        case "soccer": return ("soccerball", .green)
        case "football": return ("figure.american.football", .brown)
        case "multi": return ("sportscourt", .purple)
        default: return ("basketball", .orange)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedCourt) {
                ForEach(visibleCourts) { court in
                    Annotation(court.name, coordinate: court.coordinate) {
                        let pin = pinIcon(for: court.sport)
                        Image(systemName: pin.0)
                            .font(.title2)
                            .padding(8)
                            .background(pin.1)
                            .foregroundColor(.white)
                            .clipShape(Circle())
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

            // No sport filter at launch: basketball is the only sport.
            // It comes back when soccer is added.
            Text("Basketball courts near you")
                .font(.subheadline.bold())
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding()
        }
        .navigationTitle("Find Games Near You")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add court") { showingAddCourt = true }
            }
        }
        .sheet(item: $selectedCourt) { court in
            CourtDetailView(court: court, session: session)
        }
        .sheet(isPresented: $showingAddCourt) {
            AddCourtView(store: store, session: session,
                         coordinate: cameraPosition.region?.center
                            ?? CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321))
        }
        .overlay {
            if store.isLoading {
                ProgressView("Finding courts…").padding()
                    .background(.ultraThinMaterial).cornerRadius(10)
            }
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
            Text(court.sport == "soccer" ? "Soccer field"
                 : court.sport == "football" ? "Football field"
                 : court.sport == "multi" ? "Multi-sport pitch" : "Basketball court")
                .foregroundColor(.secondary)
            if !court.surface.isEmpty { Text("Surface: \(court.surface)") }
            Text(court.lit ? "Lit for night games" : "Not marked as lit")
                .foregroundColor(.secondary)
            Text(court.indoor ? "Indoor" : "Outdoor")
                .foregroundColor(.secondary)
            Text(court.source == "community" ? "Added by a player" : "From OpenStreetMap — hours and availability are not listed")
                .font(.footnote).foregroundColor(.secondary)

            Button("Book this court") { showingBooking = true }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                .background(Color.blue).cornerRadius(8)
            Spacer()
        }
        .padding()
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
    @State private var sport = "basketball"
    @State private var indoor = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            Text("Add a missing court").font(.title2.bold())
            Text("Dropped at the centre of your map. Other players will see it.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextField("Court or field name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            // Launch is basketball only, so the sport is fixed.
            // It becomes a picker again when soccer is added.
            Text("Sport: Basketball")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("Indoor", isOn: $indoor)
            if let errorMessage { Text(errorMessage).foregroundColor(.red) }
            Button("Add court") {
                guard let uid = session.firebaseUser?.uid else { return }
                let defaultName = sport == "soccer" ? "Soccer field"
                    : sport == "football" ? "Football field" : "Basketball court"
                store.addCommunityCourt(name: name.isEmpty ? defaultName : name,
                                        sport: sport, coordinate: coordinate,
                                        surface: "", indoor: indoor, createdBy: uid) { error in
                    if let error { errorMessage = error } else { dismiss() }
                }
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding()
            .background(Color.green).cornerRadius(8)
            Spacer()
        }
        .padding()
    }
}

/// Minimal location helper: asks once, then reports the user location.
/// Shared with the Recreational hub, which shows nearby courts.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocationCoordinate2D?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last?.coordinate
        manager.stopUpdatingLocation()
    }
}
