import XCTest
@testable import WagayaNoKondate

final class WeekIdentifierTests: XCTestCase {
    func testIdentifierFormat() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 23
        let date = calendar.date(from: components)!

        let identifier = WeekIdentifier.identifier(for: date, calendar: calendar)

        XCTAssertTrue(identifier.hasPrefix("2026-W"))
    }

    func testSameWeekProducesSameIdentifier() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let wednesday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 22))!

        XCTAssertEqual(
            WeekIdentifier.identifier(for: monday, calendar: calendar),
            WeekIdentifier.identifier(for: wednesday, calendar: calendar)
        )
    }
}
