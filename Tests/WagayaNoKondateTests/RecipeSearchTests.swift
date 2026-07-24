import XCTest
@testable import WagayaNoKondate

final class RecipeSearchTests: XCTestCase {
    private func recipe(_ title: String, genre: Genre = .other, ingredients: [String] = []) -> Recipe {
        Recipe(
            title: title,
            instructions: "-",
            servings: 2,
            genre: genre,
            ingredients: ingredients.map { Ingredient(displayName: $0, amount: "") },
            createdByMemberID: "m1"
        )
    }

    func testEmptyQueryReturnsAll() {
        let recipes = [recipe("カレー"), recipe("味噌汁")]
        XCTAssertEqual(RecipeSearch.filter(recipes, query: "  ").count, 2)
    }

    func testMatchesByTitle() {
        let recipes = [recipe("鶏のカレー"), recipe("味噌汁")]
        let result = RecipeSearch.filter(recipes, query: "カレー")
        XCTAssertEqual(result.map(\.title), ["鶏のカレー"])
    }

    func testMatchIgnoresKatakanaHiraganaDifference() {
        let recipes = [recipe("にんじんしりしり")]
        // カタカナで検索してもひらがなのタイトルにヒットする。
        XCTAssertEqual(RecipeSearch.filter(recipes, query: "ニンジン").count, 1)
    }

    func testMatchesByIngredient() {
        let recipes = [
            recipe("肉じゃが", ingredients: ["じゃがいも", "牛肉"]),
            recipe("サラダ", ingredients: ["レタス"])
        ]
        let result = RecipeSearch.filter(recipes, query: "じゃがいも")
        XCTAssertEqual(result.map(\.title), ["肉じゃが"])
    }

    func testMatchesByGenre() {
        let recipes = [recipe("パスタ", genre: .western), recipe("寿司", genre: .japanese)]
        let result = RecipeSearch.filter(recipes, query: "洋")
        XCTAssertEqual(result.map(\.title), ["パスタ"])
    }

    func testNoMatchReturnsEmpty() {
        let recipes = [recipe("カレー")]
        XCTAssertTrue(RecipeSearch.filter(recipes, query: "ラーメン").isEmpty)
    }
}
