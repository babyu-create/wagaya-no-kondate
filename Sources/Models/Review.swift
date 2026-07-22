import Foundation

struct Review: Identifiable, Codable, Hashable {
    var id: String
    var recipeID: String
    var memberID: String
    var rating: Int
    var comment: String?
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        recipeID: String,
        memberID: String,
        rating: Int,
        comment: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recipeID = recipeID
        self.memberID = memberID
        self.rating = max(1, min(5, rating))
        self.comment = comment
        self.updatedAt = updatedAt
    }
}
