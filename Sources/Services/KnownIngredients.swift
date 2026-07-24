import Foundation

/// レシピ群に登場する材料名を、表記ゆれで重複を除いて収集する。
/// 材料入力・冷蔵庫入力のサジェスト候補（過去に使った材料）として使う。
///
/// RecipeFormView と FridgeViewModel で同じ抽出ロジックが重複していたためここへ集約した。
enum KnownIngredients {
    /// 表示名を保持しつつ、正規化名（表記ゆれ吸収後）が同じものは最初の1件だけを残す。
    /// 登場順を維持する。
    static func names(from recipes: [Recipe]) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                guard seen.insert(ingredient.normalizedName).inserted else { continue }
                names.append(ingredient.displayName)
            }
        }
        return names
    }
}
