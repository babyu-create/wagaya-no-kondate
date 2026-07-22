import XCTest
@testable import WagayaNoKondate

final class ReviewAggregatorTests: XCTestCase {
    func testAverageRatingComputesMean() {
        let reviews = [
            Review(recipeID: "r1", memberID: "m1", rating: 5),
            Review(recipeID: "r1", memberID: "m2", rating: 3),
            Review(recipeID: "r2", memberID: "m1", rating: 1)
        ]

        let average = ReviewAggregator.averageRating(for: "r1", reviews: reviews)

        XCTAssertEqual(average, 4.0)
    }

    func testAverageRatingIsNilWhenNoReviews() {
        let average = ReviewAggregator.averageRating(for: "unknown", reviews: [])
        XCTAssertNil(average)
    }

    func testRecipesRatedAtLeastFiltersByThreshold() {
        let recipeA = Recipe(id: "r1", title: "A", instructions: "-", servings: 2, genre: .japanese, createdByMemberID: "m1")
        let recipeB = Recipe(id: "r2", title: "B", instructions: "-", servings: 2, genre: .japanese, createdByMemberID: "m1")
        let reviews = [
            Review(recipeID: "r1", memberID: "m1", rating: 5),
            Review(recipeID: "r1", memberID: "m2", rating: 4),
            Review(recipeID: "r2", memberID: "m1", rating: 2)
        ]

        let result = ReviewAggregator.recipes(ratedAtLeast: 4, recipes: [recipeA, recipeB], reviews: reviews)

        XCTAssertEqual(result.map(\.id), ["r1"])
    }
}
