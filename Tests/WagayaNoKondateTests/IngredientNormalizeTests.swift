import XCTest
@testable import WagayaNoKondate

final class IngredientNormalizeTests: XCTestCase {
    func testKatakanaAndHiraganaNormalizeToSameValue() {
        XCTAssertEqual(Ingredient.normalize("ジャガイモ"), Ingredient.normalize("じゃがいも"))
    }

    func testFullwidthAndHalfwidthAsciiNormalizeToSameValue() {
        XCTAssertEqual(Ingredient.normalize("Ａ牛乳"), Ingredient.normalize("A牛乳"))
    }

    func testWhitespaceIsIgnored() {
        XCTAssertEqual(Ingredient.normalize("  にんじん  "), Ingredient.normalize("にんじん"))
        XCTAssertEqual(Ingredient.normalize("にん じん"), Ingredient.normalize("にんじん"))
        XCTAssertEqual(Ingredient.normalize("にん　じん"), Ingredient.normalize("にんじん"))
    }

    func testCaseIsIgnoredForLatinCharacters() {
        XCTAssertEqual(Ingredient.normalize("Lettuce"), Ingredient.normalize("lettuce"))
    }

    func testDifferentIngredientsDoNotNormalizeToSameValue() {
        XCTAssertNotEqual(Ingredient.normalize("じゃがいも"), Ingredient.normalize("さつまいも"))
    }
}
