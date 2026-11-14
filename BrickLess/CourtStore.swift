import Foundation
import CoreLocation
import FirebaseFirestore

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
    var source: String // "openstreetmap" or "community"
    var createdBy: String?
    /// ~1 km grid cell this court sits in, e.g. "4760_-12233".
    /// Community courts are fetched by grid cell, so the map never
    /// downloads every court in the world as the app grows. OSM courts
    /// get this computed in code; community courts store it in Firestore.
    var gridKey: String = ""

    /// OSM sport tag string (e.g. "basketball;soccer") to BrickLess
    /// sport: basketball, soccer, football, or multi. A bare
    /// "football" tag means soccer in most of the world; American
    /// football is "american_football".
    static func sport(fromSportsTag tag: String) -> String {
        let hasBasketball = tag.contains("basketball")
        let hasSoccer = tag.contains("soccer")
            || tag.split(separator: ";").contains("football")
        let hasFootball = tag.contains("american_football")
        let sportCount = [hasBasketball, hasSoccer, hasFootball].filter { $0 }.count
        if sportCount > 1 { return "multi" }
        if hasFootball { return "football" }
        if hasSoccer { return "soccer" }
        return "basketball"
    }

    /// Default map label for a sport when OSM has no name for the pitch.
    static func defaultName(forSport sport: String) -> String {
        switch sport {
        case "soccer": return "Soccer field"
        case "football": return "Football field"
        default: return "Basketball court"
        }
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
/// requests are kept small (5 km radius, 100 results max).
class CourtStore: ObservableObject {
    /// Launch sports: basketball only. The app starts in the US with one
    /// sport, then expands in this order: soccer, then American football.
    /// Add "soccer" and "american_football" here and the map query,
    /// Add Court and the signup sports picker all pick them up.
    /// (US-first note: in OSM a bare "football" tag usually means soccer
    /// outside the US; American football is "american_football".)
    static let launchSports = ["basketball"]

    @Published var courts: [Court] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var lastFetchKey = ""

    func fetchCourts(around coordinate: CLLocationCoordinate2D, radiusMeters: Int = 5000) {
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
        out center 100;
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
    func addCommunityCourt(name: String, sport: String, coordinate: CLLocationCoordinate2D,
                           surface: String, indoor: Bool, createdBy: String,
                           completion: @escaping (String?) -> Void) {
        let court = Court(id: UUID().uuidString, name: name, sport: sport,
                          latitude: coordinate.latitude, longitude: coordinate.longitude,
                          surface: surface, lit: false, indoor: indoor,
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
