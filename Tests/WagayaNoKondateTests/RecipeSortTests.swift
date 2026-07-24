import XCTest
@testable import WagayaNoKondate

final class RecipeSortTests: XCTestCase {
    private func recipe(id: String, title: String, daysAgo: Int) -> Recipe {
        Recipe(
            id: id,
            title: title,
            instructions: "-",
            servings: 2,
            genre: .other,
            createdByMemberID: "m1",
            createdAt: Date(timeIntervalSince1970: TimeInterval(10_000 - daysAgo))
        )
    }

    func testNewestOrdersByCreatedAtDescending() {
        let recipes = [
            recipe(id: "old", title: "古い", daysAgo: 100),
            recipe(id: "new", title: "新しい", daysAgo: 0)
        ]

        let sorted = RecipeSort.sorted(recipes, by: .newest, ratings: [:])

        XCTAssertEqual(sorted.map(\.id), ["new", "old"])
    }

    func testRatingHighOrdersByRatingThenNewest() {
        let recipes = [
            recipe(id: "low", title: "A", daysAgo: 0),
            recipe(id: "high", title: "B", daysAgo: 100),
            recipe(id: "none", title: "C", daysAgo: 50)
        ]
        let ratings = ["low": 2.0, "high": 5.0]

        let sorted = RecipeSort.sorted(recipes, by: .ratingHigh, ratings: ratings)

        // 評価5 → 評価2 → 評価なし の順。
        XCTAssertEqual(sorted.map(\.id), ["high", "low", "none"])
    }

    func testTitleAscOrdersAlphabetically() {
        let recipes = [
            recipe(id: "c", title: "C", daysAgo: 0),
            recipe(id: "a", title: "A", daysAgo: 0),
            recipe(id: "b", title: "B", daysAgo: 0)
        ]

        let sorted = RecipeSort.sorted(recipes, by: .titleAsc, ratings: [:])

        XCTAssertEqual(sorted.map(\.id), ["a", "b", "c"])
    }

    func testSortDoesNotMutateOrDropRecipes() {
        let recipes = [
            recipe(id: "a", title: "A", daysAgo: 1),
            recipe(id: "b", title: "B", daysAgo: 2)
        ]
        let sorted = RecipeSort.sorted(recipes, by: .ratingHigh, ratings: [:])
        XCTAssertEqual(Set(sorted.map(\.id)), Set(["a", "b"]))
    }
}
