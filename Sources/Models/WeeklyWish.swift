import Foundation

struct WeeklyWish: Identifiable, Codable, Hashable {
    var id: String
    var recipeID: String
    var memberID: String
    var weekOf: String

    init(
        id: String = UUID().uuidString,
        recipeID: String,
        memberID: String,
        weekOf: String = WeekIdentifier.current()
    ) {
        self.id = id
        self.recipeID = recipeID
        self.memberID = memberID
        self.weekOf = weekOf
    }
}

enum WeekIdentifier {
    static func current(calendar: Calendar = .current, date: Date = Date()) -> String {
        identifier(for: date, calendar: calendar)
    }

    static func identifier(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let year = comps.yearForWeekOfYear, let week = comps.weekOfYear else { return "" }
        return String(format: "%04d-W%02d", year, week)
    }
}
