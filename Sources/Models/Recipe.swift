import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var instructions: String
    var sourceURL: URL?
    var servings: Int
    var costPerServing: Int?
    var genre: Genre
    var ingredients: [Ingredient]
    var createdByMemberID: String
    var createdAt: Date
    var localImageURL: URL?

    init(
        id: String = UUID().uuidString,
        title: String,
        instructions: String,
        sourceURL: URL? = nil,
        servings: Int,
        costPerServing: Int? = nil,
        genre: Genre,
        ingredients: [Ingredient] = [],
        createdByMemberID: String,
        createdAt: Date = Date(),
        localImageURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.sourceURL = sourceURL
        self.servings = servings
        self.costPerServing = costPerServing
        self.genre = genre
        self.ingredients = ingredients
        self.createdByMemberID = createdByMemberID
        self.createdAt = createdAt
        self.localImageURL = localImageURL
    }

    enum CodingKeys: String, CodingKey {
        case id, title, instructions, sourceURL, servings, costPerServing, genre, ingredients, createdByMemberID, createdAt, localImageURL
    }
}
