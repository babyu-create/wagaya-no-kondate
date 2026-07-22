import Foundation

enum FridgeMatcher {
    struct MatchResult: Identifiable {
        let recipe: Recipe
        let missingIngredients: [Ingredient]

        var id: String { recipe.id }
        var isFullyAvailable: Bool { missingIngredients.isEmpty }
    }

    static func match(recipes: [Recipe], fridgeItems: [FridgeItem]) -> [MatchResult] {
        let available = Set(fridgeItems.map(\.normalizedName))
        return recipes
            .map { recipe in
                let missing = recipe.ingredients.filter { !available.contains($0.normalizedName) }
                return MatchResult(recipe: recipe, missingIngredients: missing)
            }
            .sorted { $0.missingIngredients.count < $1.missingIngredients.count }
    }
}
