import XCTest
@testable import Logbook

final class DatePersistenceTests: XCTestCase {
    func testFractionalDateRoundTripAndLegacyWholeSecondRead() throws {
        let precise = Date(timeIntervalSince1970: 1_800_000_000.123)
        var state = LogbookState.empty
        state.lastModified = precise

        let encoded = try JSONEncoder.logbook.encode(state)
        let text = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertTrue(text.contains(".123"))
        let reopened = try JSONDecoder.logbook.decode(LogbookState.self, from: encoded)
        XCTAssertLessThan(abs(reopened.lastModified.timeIntervalSince(precise)), 0.001)

        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var legacy = object
        legacy["lastModified"] = "2027-01-15T08:00:00Z"
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        let legacyState = try JSONDecoder.logbook.decode(LogbookState.self, from: legacyData)
        XCTAssertEqual(legacyState.lastModified.timeIntervalSince1970, 1_800_000_000, accuracy: 0.001)
    }
}
