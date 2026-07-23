import XCTest
@testable import WagayaNoKondate

final class FridgeMatcherTests: XCTestCase {
    func testFullyAvailableRecipeHasNoMissingIngredients() {
        let recipe = Recipe(
            title: "肉じゃが",
            instructions: "煮る",
            servings: 4,
            genre: .japanese,
            ingredients: [
                Ingredient(displayName: "じゃがいも", amount: "3個"),
                Ingredient(displayName: "にんじん", amount: "1本")
            ],
            createdByMemberID: "member-1"
        )
        let fridge = [
            FridgeItem(displayName: "じゃがいも", updatedByMemberID: "member-1"),
            FridgeItem(displayName: "にんじん", updatedByMemberID: "member-1"),
            FridgeItem(displayName: "牛肉", updatedByMemberID: "member-1")
        ]

        let results = FridgeMatcher.match(recipes: [recipe], fridgeItems: fridge)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].isFullyAvailable)
        XCTAssertTrue(results[0].missingIngredients.isEmpty)
    }

    func testMissingIngredientsAreReportedAndSortedByFewestMissing() {
        let recipeA = Recipe(
            title: "カレー",
            instructions: "煮る",
            servings: 4,
            genre: .other,
            ingredients: [
                Ingredient(displayName: "じゃがいも", amount: "3個"),
                Ingredient(displayName: "牛肉", amount: "300g"),
                Ingredient(displayName: "カレールー", amount: "1箱")
            ],
            createdByMemberID: "member-1"
        )
        let recipeB = Recipe(
            title: "味噌汁",
            instructions: "煮る",
            servings: 4,
            genre: .japanese,
            ingredients: [
                Ingredient(displayName: "味噌", amount: "大さじ2"),
                Ingredient(displayName: "豆腐", amount: "半丁")
            ],
            createdByMemberID: "member-1"
        )
        let fridge = [
            FridgeItem(displayName: "じゃがいも", updatedByMemberID: "member-1"),
            FridgeItem(displayName: "味噌", updatedByMemberID: "member-1"),
            FridgeItem(displayName: "豆腐", updatedByMemberID: "member-1")
        ]

        let results = FridgeMatcher.match(recipes: [recipeA, recipeB], fridgeItems: fridge)

        XCTAssertEqual(results.first?.recipe.title, "味噌汁")
        XCTAssertTrue(results.first?.isFullyAvailable ?? false)
        XCTAssertEqual(results.last?.recipe.title, "カレー")
        XCTAssertEqual(results.last?.missingIngredients.count, 2)
    }

    func testNameMatchingIgnoresWhitespaceAndCase() {
        let recipe = Recipe(
            title: "サラダ",
            instructions: "混ぜる",
            servings: 2,
            genre: .western,
            ingredients: [Ingredient(displayName: "  Lettuce ", amount: "1個")],
            createdByMemberID: "member-1"
        )
        let fridge = [FridgeItem(displayName: "lettuce", updatedByMemberID: "member-1")]

        let results = FridgeMatcher.match(recipes: [recipe], fridgeItems: fridge)

        XCTAssertTrue(results[0].isFullyAvailable)
    }

    func testNameMatchingIgnoresKatakanaHiraganaDifference() {
        let recipe = Recipe(
            title: "肉じゃが",
            instructions: "煮る",
            servings: 4,
            genre: .japanese,
            ingredients: [Ingredient(displayName: "ジャガイモ", amount: "3個")],
            createdByMemberID: "member-1"
        )
        let fridge = [FridgeItem(displayName: "じゃがいも", updatedByMemberID: "member-1")]

        let results = FridgeMatcher.match(recipes: [recipe], fridgeItems: fridge)

        XCTAssertTrue(results[0].isFullyAvailable)
    }

    func testNameMatchingIgnoresFullwidthHalfwidthDifference() {
        let recipe = Recipe(
            title: "テスト",
            instructions: "-",
            servings: 1,
            genre: .other,
            ingredients: [Ingredient(displayName: "Ａ牛乳", amount: "1本")],
            createdByMemberID: "member-1"
        )
        let fridge = [FridgeItem(displayName: "A牛乳", updatedByMemberID: "member-1")]

        let results = FridgeMatcher.match(recipes: [recipe], fridgeItems: fridge)

        XCTAssertTrue(results[0].isFullyAvailable)
    }
}
