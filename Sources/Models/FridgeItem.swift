import Foundation

struct FridgeItem: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var quantity: String?
    var updatedByMemberID: String
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        displayName: String,
        quantity: String? = nil,
        updatedByMemberID: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.quantity = quantity
        self.updatedByMemberID = updatedByMemberID
        self.updatedAt = updatedAt
    }

    var normalizedName: String {
        Ingredient.normalize(displayName)
    }
}
