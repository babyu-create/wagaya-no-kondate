import XCTest
@testable import WagayaNoKondate

final class KnownIngredientsTests: XCTestCase {
    private func recipe(ingredients: [Ingredient]) -> Recipe {
        Recipe(title: "r", instructions: "-", servings: 2, genre: .other, ingredients: ingredients, createdByMemberID: "m1")
    }

    func testCollectsDisplayNamesAcrossRecipes() {
        let recipes = [
            recipe(ingredients: [Ingredient(displayName: "にんじん", amount: "1本")]),
            recipe(ingredients: [Ingredient(displayName: "たまねぎ", amount: "2個")])
        ]

        let names = KnownIngredients.names(from: recipes)

        XCTAssertEqual(names, ["にんじん", "たまねぎ"])
    }

    func testDeduplicatesByNormalizedName() {
        // 「ニンジン」(カタカナ) と「にんじん」(ひらがな) は同じ材料として1件に集約。
        let recipes = [
            recipe(ingredients: [Ingredient(displayName: "にんじん", amount: "1本")]),
            recipe(ingredients: [Ingredient(displayName: "ニンジン", amount: "2本")])
        ]

        let names = KnownIngredients.names(from: recipes)

        XCTAssertEqual(names, ["にんじん"])
    }

    func testKeepsFirstAppearanceOrderAndDisplayName() {
        let recipes = [
            recipe(ingredients: [
                Ingredient(displayName: "じゃがいも", amount: "2個"),
                Ingredient(displayName: "にんじん", amount: "1本")
            ]),
            recipe(ingredients: [
                Ingredient(displayName: "ジャガイモ", amount: "3個")
            ])
        ]

        let names = KnownIngredients.names(from: recipes)

        XCTAssertEqual(names, ["じゃがいも", "にんじん"])
    }

    func testEmptyRecipesYieldsEmpty() {
        XCTAssertTrue(KnownIngredients.names(from: []).isEmpty)
    }
}
