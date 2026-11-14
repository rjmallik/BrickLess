import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseFirestoreSwift

/// A basketball court, soccer field, or football field on the map.
struct Court: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var sport: String // basketball, soccer, football, or multi
    var latitude: Double
    var longitude: Double
    var surface: String
    var lit: Bool
    var indoor: Bool
    /// Paid booking link for the venue: the venue's own site, where the
    /// player books and pays. Nil for venues that do not take bookings.
    /// Only ever shown when the venue is indoor, verified, and this link
    /// is set (see canShowBookingLink). We take no payment in-app.
    var bookingURL: String? = nil
    /// Verified by PlayMatch (admin). OpenStreetMap venues are trusted
    /// public data and are verified. Community (user-submitted) venues
    /// start unverified — a pending request — and their booking link
    /// stays hidden until verified, so a fake venue cannot carry a
    /// scam booking link.
    var verified: Bool = false
    var source: String // "openstreetmap" or "community"
    var createdBy: String?
    /// ~1 km grid cell this court sits in, e.g. "4760_-12233".
    /// Community courts are fetched by grid cell, so the map never
    /// downloads every court in the world as the app grows. OSM courts
    /// get this computed in code; community courts store it in Firestore.
    var gridKey: String = ""

    /// OSM sport tag string (e.g. "basketball;soccer") to PlayMatch
    /// sport: one of the launch sports, or "multi" when the pitch serves
    /// several. A bare "football" tag means soccer in most of the world;
    /// American football is "american_football".
    static func sport(fromSportsTag tag: String) -> String {
        let parts = tag.split(separator: ";").map(String.init)
        let hasBasketball = parts.contains("basketball")
        let hasSoccer = parts.contains("soccer") || parts.contains("football")
        let hasFootball = parts.contains("american_football")
        let hasTennis = parts.contains("tennis")
        let hasPickleball = parts.contains("pickleball")
        let hasTableTennis = parts.contains("table_tennis")
        let found = ["basketball": hasBasketball, "soccer": hasSoccer,
                     "football": hasFootball, "tennis": hasTennis,
                     "pickleball": hasPickleball, "table_tennis": hasTableTennis]
            .filter { $0.value }.map { $0.key }
        if found.count > 1 { return "multi" }
        return found.first ?? "basketball"
    }

    /// Default map label for a sport when OSM has no name for the pitch.
    static func defaultName(forSport sport: String) -> String {
        switch sport {
        case "soccer": return "Soccer field"
        case "football": return "Football field"
        case "tennis": return "Tennis court"
        case "pickleball": return "Pickleball court"
        case "table_tennis": return "Table tennis table"
        case "multi": return "Multi-sport pitch"
        default: return "Basketball court"
        }
    }

    /// The venue word for a sport: what the place is called. Basketball,
    /// tennis and pickleball are played on courts, soccer and American
    /// football on fields, table tennis on a table, and a multi-sport
    /// pitch is a pitch. "american_football" is the OSM tag form of
    /// "football"; it can leak in from community courts added before
    /// the Add Court picker stored Court.sport tags, and it is still a
    /// field. Pure so it is unit-testable.
    static func venueWord(forSport sport: String) -> String {
        switch sport {
        case "soccer", "football", "american_football": return "field"
        case "table_tennis": return "table"
        case "multi": return "pitch"
        default: return "court"
        }
    }

    /// The plural venue word: "courts", "fields", "tables", "pitches".
    /// ("pitch" pluralises to "pitches", not "pitchs".)
    static func venueWordPlural(forSport sport: String) -> String {
        switch venueWord(forSport: sport) {
        case "field": return "fields"
        case "table": return "tables"
        case "pitch": return "pitches"
        default: return "courts"
        }
    }

    /// A raw booking-link string, validated: non-empty, a well-formed
    /// http(s) URL with a host. Returns nil for a missing, blank, or
    /// malformed link. Pure so it is unit-testable.
    static func validatedBookingURLString(_ raw: String?) -> URL? {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else { return nil }
        return url
    }

    /// The venue's booking URL, if it has a usable one. Pure so it is
    /// unit-testable.
    static func validatedBookingURL(_ court: Court) -> URL? {
        validatedBookingURLString(court.bookingURL)
    }

    /// Whether the paid "Book this [venue]" link may be shown: the venue
    /// must be indoor, verified, and carry a booking link. Any condition
    /// failing hides the link, so an outdoor or unverified venue never
    /// advertises a paid booking. Pure so it is unit-testable.
    static func canShowBookingLink(_ court: Court) -> Bool {
        guard court.indoor, court.verified else { return false }
        return validatedBookingURL(court) != nil
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Grid cell for a coordinate, matching the Overpass cache key below.
    /// One cell is ~1.1 km of latitude; longitude cells are narrower
    /// away from the equator, which is fine for a neighbourhood fetch.
    static func gridKey(latitude: Double, longitude: Double) -> String {
        "\(Int(latitude * 100))_\(Int(longitude * 100))"
    }

    /// This cell plus its 8 neighbours, for a ~3 km fetch around a point.
    /// Firestore `in` takes up to 30 values; 9 fits.
    static func nearbyGridKeys(around coordinate: CLLocationCoordinate2D) -> [String] {
        let lat = Int(coordinate.latitude * 100)
        let lon = Int(coordinate.longitude * 100)
        var keys: [String] = []
        for dLat in -1...1 {
            for dLon in -1...1 {
                keys.append("\(lat + dLat)_\(lon + dLon)")
            }
        }
        return keys
    }
}

/// Courts come from two places, because no single source has them all:
/// 1. OpenStreetMap, via the Overpass API: every `leisure=pitch` tagged
///    with a launch sport near the user. Free, global, and
///    community-mapped, but coverage is uneven: a court only shows if
///    someone mapped it, and OSM has no hours, fees or live availability.
/// 2. Community courts in Firestore (`courts/{id}`), added by players
///    in the app. These fill the gaps and can carry booking info.
///
/// Overpass is a shared public service: results are cached per area and
/// requests are kept small (25 km radius, 200 results max).
class CourtStore: ObservableObject {
    /// Launch sports: all phases except golf (phase 4). Basketball
    /// (phase 1), soccer + American football (phase 2), tennis +
    /// pickleball + table tennis (phase 3). The map query, Add Court and
    /// the signup sports picker all pick them up from here and from
    /// UserProfile.allSports (the display-name form of the same list).
    /// (US-first note: in OSM a bare "football" tag usually means soccer
    /// outside the US; American football is "american_football".)
    static let launchSports = ["basketball", "soccer", "american_football",
                               "tennis", "pickleball", "table_tennis"]

    @Published var courts: [Court] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var lastFetchKey = ""

    /// Wide enough to cover a metro area (25 km), not just the
    /// immediate neighbourhood, so players see venues across town.
    func fetchCourts(around coordinate: CLLocationCoordinate2D, radiusMeters: Int = 25000) {
        // Cache per ~1 km grid cell so panning the map does not re-query.
        let key = "\(Int(coordinate.latitude * 100))_\(Int(coordinate.longitude * 100))"
        guard key != lastFetchKey else { return }
        lastFetchKey = key
        isLoading = true

        fetchFromOverpass(around: coordinate, radiusMeters: radiusMeters) { [weak self] osmCourts in
            guard let self else { return }
            self.fetchCommunityCourts(around: coordinate) { community in
                var all = osmCourts + community
                var seen = Set<String>()
                all = all.filter { seen.insert($0.id).inserted }
                self.courts = all.sorted { $0.name < $1.name }
                self.isLoading = false
            }
        }
    }

    // MARK: - OpenStreetMap / Overpass

    private struct OverpassResponse: Decodable {
        struct Element: Decodable {
            var type: String
            var id: Int
            var lat: Double?
            var lon: Double?
            var center: Center?
            var tags: [String: String]?
            struct Center: Decodable { var lat: Double; var lon: Double }
        }
        var elements: [Element]
    }

    private func fetchFromOverpass(around coordinate: CLLocationCoordinate2D,
                                   radiusMeters: Int,
                                   completion: @escaping ([Court]) -> Void) {
        let sportPattern = CourtStore.launchSports.joined(separator: "|")
        let query = """
        [out:json][timeout:25];
        (
          node["leisure"="pitch"]["sport"~"\(sportPattern)"](around:\(radiusMeters),\(coordinate.latitude),\(coordinate.longitude));
          way["leisure"="pitch"]["sport"~"\(sportPattern)"](around:\(radiusMeters),\(coordinate.latitude),\(coordinate.longitude));
        );
        out center 200;
        """
        var request = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        request.httpMethod = "POST"
        request.httpBody = "data=\(query)".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(OverpassResponse.self, from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let courts: [Court] = response.elements.compactMap { element in
                let lat = element.lat ?? element.center?.lat
                let lon = element.lon ?? element.center?.lon
                guard let lat, let lon else { return nil }
                let tags = element.tags ?? [:]
                // Skip fields the public cannot use (e.g. private school
                // or club fields). Validated Nov 7: one football pitch
                // near Seattle is access=private.
                guard tags["access"] != "private" else { return nil }
                let sports = tags["sport"] ?? "basketball"
                // OSM tags: basketball, soccer, american_football.
                // A bare "football" tag means soccer in most of the world.
                let sport = Court.sport(fromSportsTag: sports)
                let defaultName = Court.defaultName(forSport: sport)
                return Court(
                    id: "osm-\(element.type)-\(element.id)",
                    name: tags["name"] ?? defaultName,
                    sport: sport,
                    latitude: lat, longitude: lon,
                    surface: tags["surface"] ?? "",
                    lit: tags["lit"] == "yes",
                    indoor: tags["indoor"] == "yes",
                    // OSM is trusted public data, so its venues are
                    // verified. (Community venues are the ones that
                    // start unverified; see addCommunityCourt.)
                    verified: true,
                    source: "openstreetmap",
                    gridKey: Court.gridKey(latitude: lat, longitude: lon)
                )
            }
            DispatchQueue.main.async { completion(courts) }
        }.resume()
    }

    // MARK: - Community courts (Firestore)

    /// Only courts in the ~3 km grid around the user, never the whole
    /// collection. The old version fetched every community court with a
    /// 200-doc limit, which breaks once courts exist across the country.
    private func fetchCommunityCourts(around coordinate: CLLocationCoordinate2D,
                                      completion: @escaping ([Court]) -> Void) {
        db.collection("courts")
            .whereField("gridKey", in: Court.nearbyGridKeys(around: coordinate))
            .limit(to: 200)
            .getDocuments { snapshot, _ in
                let courts = snapshot?.documents.compactMap { try? $0.data(as: Court.self) } ?? []
                completion(courts)
            }
    }

    /// Let a player add a court the map is missing. It shows for everyone.
    /// A new community venue is always unverified (a pending request):
    /// the creator cannot self-verify, and its booking link stays hidden
    /// until an admin verifies it. The booking link is only stored when
    /// the venue is indoor and the creator said it takes bookings.
    func addCommunityCourt(name: String, sport: String, coordinate: CLLocationCoordinate2D,
                           surface: String, indoor: Bool, createdBy: String,
                           bookingURL: String? = nil,
                           completion: @escaping (String?) -> Void) {
        let court = Court(id: UUID().uuidString, name: name, sport: sport,
                          latitude: coordinate.latitude, longitude: coordinate.longitude,
                          surface: surface, lit: false, indoor: indoor,
                          bookingURL: bookingURL,
                          verified: false,
                          source: "community", createdBy: createdBy,
                          gridKey: Court.gridKey(latitude: coordinate.latitude,
                                                 longitude: coordinate.longitude))
        do {
            try db.collection("courts").document(court.id).setData(from: court)
            courts.append(court)
            completion(nil)
        } catch {
            completion(error.localizedDescription)
        }
    }
}
