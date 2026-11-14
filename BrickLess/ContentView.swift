import SwiftUI
import CoreLocation
import Firebase

struct ContentView: View {
    @StateObject private var session = SessionStore()

    var body: some View {
        NavigationView {
            if session.isLoggedIn {
                if session.needsProfileSetup {
                    // Step 2 of account setup, before Home.
                    ProfileSetupView(session: session)
                        .navigationBarHidden(true)
                } else {
                    MainAppView(session: session)
                }
            } else {
                VStack {
                    if session.isLoading {
                        // Signing in: a spinner only. The launch splash
                        // (LoadingView, in PlayMatchApp) must not be reused
                        // here: after 2s it opens a second ContentView with
                        // a second, empty SessionStore.
                        ProgressView("Signing you in…")
                            .padding()
                    } else {
                        // Show the LoginView. It displays session.loginError
                        // itself (via the errorMessage binding), so this
                        // view must not print it again underneath.
                        LoginView(session: session, errorMessage: $session.loginError)
                    }
                }
                .navigationBarHidden(true) // Hide navigation bar
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Use stack navigation style to handle navigation views correctly
    }
}



struct MainAppView: View {
    @ObservedObject var session: SessionStore

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Text("PlayMatch").font(.custom("Arial", size: 60)).fontWeight(.bold).foregroundColor(.white)
                NavigationLink(destination: RecreationalView(session: session)) {
                    Text("Recreational").foregroundColor(.white).font(.title)
                    .frame(maxWidth: .infinity, minHeight: 250).background(Color.blue).cornerRadius(10)
                }
                .padding(.vertical, 35)
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}



struct RecreationalView: View {
    @ObservedObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var courtStore = CourtStore()
    @StateObject private var locationManager = LocationManager()

    /// The three courts closest to the user, so the map's results are
    /// visible on the hub itself instead of hidden behind a tile.
    private var nearestCourts: [(court: Court, distance: Double?)] {
        let userLocation = locationManager.location.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }
        let withDistance = courtStore.courts.map { court -> (Court, Double?) in
            guard let userLocation else { return (court, nil) }
            let d = userLocation.distance(from: CLLocation(latitude: court.latitude,
                                                           longitude: court.longitude))
            return (court, d)
        }
        return Array(withDistance.sorted { ($0.1 ?? .infinity) < ($1.1 ?? .infinity) }.prefix(3))
    }

    private func distanceLabel(_ meters: Double?) -> String {
        guard let meters else { return "" }
        if meters < 1000 { return "\(Int(meters)) m away" }
        return String(format: "%.1f km away", meters / 1000)
    }

    private func sportLabel(_ sport: String) -> String {
        switch sport {
        case "soccer": return "Soccer"
        case "football": return "Football"
        case "tennis": return "Tennis"
        case "pickleball": return "Pickleball"
        case "table_tennis": return "Table Tennis"
        case "multi": return "Multi-sport"
        default: return "Basketball"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: geometry.size.width * 0.05) {  // Reduced horizontal whitespace
                        NavigationLink(destination: CourtMapView(session: session)) {
                            Text("Find Games Near You")
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(15) // Curved edges
                        }
                        NavigationLink(destination: ProfileView(session: session)) {
                            Text("My Profile")
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(15) // Curved edges
                        }
                    }
                    HStack(spacing: geometry.size.width * 0.05) {  // Reduced horizontal whitespace
                        NavigationLink(destination: FriendsView(session: session, selectedTab: 1)) {
                            Text("Add Friends")
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15) // Curved edges
                        }
                        NavigationLink(destination: FriendsView(session: session, selectedTab: 0)) {
                            Text("My Guys")
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(15) // Curved edges
                        }
                    }
                    HStack(spacing: geometry.size.width * 0.05) {  // Reduced horizontal whitespace
                        NavigationLink(destination: EventsView(session: session)) {
                            Text("Games")
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(15) // Curved edges
                        }
                        NavigationLink(destination: PlayersView(session: session)) {
                            Text("Players")
                                .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(15) // Curved edges
                        }
                    }

                    // Courts near you, right on the hub: the map's results
                    // are shown here, not just behind the Find Games tile.
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Courts near you")
                                .font(.headline)
                            Spacer()
                            NavigationLink("See map", destination: CourtMapView(session: session))
                                .font(.subheadline)
                        }
                        if courtStore.isLoading && courtStore.courts.isEmpty {
                            ProgressView("Finding courts near you…")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if nearestCourts.isEmpty {
                            Text("No courts found near you yet. Tap Add court on the map to add one.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(nearestCourts, id: \.court.id) { item in
                                NavigationLink(destination: CourtMapView(session: session)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.court.name)
                                                .font(.subheadline.bold())
                                            Text(sportLabel(item.court.sport))
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(distanceLabel(item.distance))
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text("Back")
                .frame(minWidth: 84, minHeight: 34) // Minimum recommended tap target size for iOS
                .background(Color.gray) // Give it a gray background
                .foregroundColor(.white) // Text color
                .cornerRadius(5) // Rounded corners
        })
        .navigationBarHidden(false) // Show the navigation bar
        .onAppear {
            locationManager.requestPermission()
            courtStore.fetchCourts(around: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321))
        }
        .onReceive(locationManager.$location) { location in
            // onChange can't watch CLLocationCoordinate2D: it is not
            // Equatable. onReceive on the @Published value needs no
            // Equatable conformance.
            guard let location else { return }
            courtStore.fetchCourts(around: location)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
