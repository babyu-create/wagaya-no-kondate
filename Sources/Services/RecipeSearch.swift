import Foundation

/// レシピ一覧の検索。タイトル・材料名・ジャンルを対象に、表記ゆれを吸収して絞り込む。
/// 「ニンジン」で検索しても「にんじん」を含むレシピがヒットする。
enum RecipeSearch {
    static func filter(_ recipes: [Recipe], query: String) -> [Recipe] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return recipes }

        let normalizedQuery = Ingredient.normalize(trimmed)
        return recipes.filter { recipe in
            if Ingredient.normalize(recipe.title).contains(normalizedQuery) { return true }
            if recipe.genre.rawValue.contains(trimmed) { return true }
            return recipe.ingredients.contains { $0.normalizedName.contains(normalizedQuery) }
        }
    }
}
