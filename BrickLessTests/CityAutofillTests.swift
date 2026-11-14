import XCTest
@testable import PlayMatch

/// Profile-setup location autofill: display text for a suggestion
/// and the bundled US-city fallback matching (prefix first,
/// case-insensitive, capped at five).
final class CityAutofillTests: XCTestCase {

    func testDisplayTextBareTitleWhenNoSubtitle() {
        XCTAssertEqual(LocationSuggestions.displayText(title: "Seattle", subtitle: ""),
                       "Seattle")
    }

    func testDisplayTextKeepsStateFromSubtitle() {
        // "California, United States" -> just the state part.
        XCTAssertEqual(LocationSuggestions.displayText(title: "San Francisco",
                                                       subtitle: "California, United States"),
                       "San Francisco, California")
        XCTAssertEqual(LocationSuggestions.displayText(title: "Austin",
                                                       subtitle: "TX, United States"),
                       "Austin, TX")
    }

    func testMatchingCitiesIsPrefixFirstAndCaseInsensitive() {
        let matches = LocationSuggestions.matchingCities(query: "san")
        XCTAssertTrue(matches.contains("San Francisco, CA"))
        XCTAssertTrue(matches.contains("San Diego, CA"))
        XCTAssertTrue(matches.contains("San Jose, CA"))
        XCTAssertTrue(matches.contains("San Antonio, TX"))
        // All of them start with the query, so they rank as prefix matches.
        XCTAssertTrue(matches.allSatisfy { $0.lowercased().hasPrefix("san") })
    }

    func testMatchingCitiesCapsAtFive() {
        // "s" matches far more than five cities; only five come back.
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "s").count, 5)
    }

    func testMatchingCitiesFindsSubstringMatches() {
        // "york" is not a prefix of any city name, but New York contains it.
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "york"), ["New York, NY"])
    }

    func testMatchingCitiesBlankQueryMatchesNothing() {
        XCTAssertEqual(LocationSuggestions.matchingCities(query: ""), [])
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "   "), [])
    }

    func testMatchingCitiesNoMatchIsEmpty() {
        XCTAssertEqual(LocationSuggestions.matchingCities(query: "zzz"), [])
    }
}
