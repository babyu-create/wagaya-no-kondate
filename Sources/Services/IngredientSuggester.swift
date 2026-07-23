import Foundation

/// 材料名入力中に候補を出す。定番食材リスト＋過去に使った材料名から、
/// 入力中の文字列を含むものを絞り込む(要件§9-2: 選択式＋自由入力の併用)。
enum IngredientSuggester {
    static func suggestions(for query: String, knownNames: [String] = [], limit: Int = 8) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let normalizedQuery = Ingredient.normalize(trimmedQuery)
        var seen = Set<String>()
        var results: [String] = []

        for candidate in CommonIngredients.all + knownNames {
            let normalizedCandidate = Ingredient.normalize(candidate)
            guard normalizedCandidate.contains(normalizedQuery) else { continue }
            guard !seen.contains(normalizedCandidate) else { continue }
            seen.insert(normalizedCandidate)
            results.append(candidate)
            if results.count >= limit { break }
        }

        return results
    }
}
