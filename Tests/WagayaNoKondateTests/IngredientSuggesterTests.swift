import XCTest
@testable import WagayaNoKondate

final class IngredientSuggesterTests: XCTestCase {
    func testEmptyQueryReturnsNoSuggestions() {
        XCTAssertTrue(IngredientSuggester.suggestions(for: "").isEmpty)
        XCTAssertTrue(IngredientSuggester.suggestions(for: "   ").isEmpty)
    }

    func testMatchesCommonIngredientByPartialInput() {
        let results = IngredientSuggester.suggestions(for: "じゃが")
        XCTAssertTrue(results.contains("じゃがいも"))
    }

    func testMatchIgnoresKatakanaHiraganaDifference() {
        let results = IngredientSuggester.suggestions(for: "ジャガ")
        XCTAssertTrue(results.contains("じゃがいも"))
    }

    func testIncludesKnownNamesNotInCommonList() {
        let results = IngredientSuggester.suggestions(for: "オリーブ", knownNames: ["オリーブオイル"])
        XCTAssertTrue(results.contains("オリーブオイル"))
    }

    func testNoMatchReturnsEmpty() {
        let results = IngredientSuggester.suggestions(for: "そんざいしないやさい12345")
        XCTAssertTrue(results.isEmpty)
    }

    func testDoesNotExceedLimit() {
        let manyKnownNames = (0..<50).map { "特殊食材\($0)" }
        let results = IngredientSuggester.suggestions(for: "特殊食材", knownNames: manyKnownNames, limit: 5)
        XCTAssertEqual(results.count, 5)
    }
}
