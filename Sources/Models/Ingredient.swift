import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var displayName: String
    var amount: String

    static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var normalizedName: String {
        Ingredient.normalize(displayName)
    }
}
