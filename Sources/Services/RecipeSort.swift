import Foundation

/// レシピ一覧の並び替え順。
enum RecipeSortOrder: String, CaseIterable, Identifiable {
    case newest = "新着順"
    case ratingHigh = "評価が高い順"
    case titleAsc = "名前順"

    var id: String { rawValue }
    var systemImage: String {
        switch self {
        case .newest: return "clock"
        case .ratingHigh: return "star"
        case .titleAsc: return "textformat"
        }
    }
}

enum RecipeSort {
    static func sorted(
        _ recipes: [Recipe],
        by order: RecipeSortOrder,
        ratings: [String: Double]
    ) -> [Recipe] {
        switch order {
        case .newest:
            return recipes.sorted { $0.createdAt > $1.createdAt }
        case .ratingHigh:
            // 評価未登録は最下位(-1)扱い。同点は新着順で安定させる。
            return recipes.sorted { lhs, rhs in
                let left = ratings[lhs.id] ?? -1
                let right = ratings[rhs.id] ?? -1
                if left != right { return left > right }
                return lhs.createdAt > rhs.createdAt
            }
        case .titleAsc:
            return recipes.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
    }
}
