import Foundation

enum ReviewAggregator {
    static func averageRating(for recipeID: String, reviews: [Review]) -> Double? {
        let relevant = reviews.filter { $0.recipeID == recipeID }
        guard !relevant.isEmpty else { return nil }
        let total = relevant.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(relevant.count)
    }

    static func recipes(ratedAtLeast threshold: Int, recipes: [Recipe], reviews: [Review]) -> [Recipe] {
        recipes.filter { recipe in
            guard let average = averageRating(for: recipe.id, reviews: reviews) else { return false }
            return average >= Double(threshold)
        }
    }
}
