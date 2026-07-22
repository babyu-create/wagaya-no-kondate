import Foundation

enum Genre: String, Codable, CaseIterable, Identifiable, Hashable {
    case japanese = "和"
    case western = "洋"
    case chinese = "中"
    case other = "他"

    var id: String { rawValue }
}
