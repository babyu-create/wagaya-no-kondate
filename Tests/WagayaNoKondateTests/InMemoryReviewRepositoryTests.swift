import XCTest
@testable import WagayaNoKondate

final class InMemoryReviewRepositoryTests: XCTestCase {
    func testUpsertOverwritesExistingReviewForSameMemberAndRecipe() async throws {
        let repository = InMemoryReviewRepository()

        _ = try await repository.upsert(recipeID: "r1", memberID: "m1", rating: 3, comment: nil)
        _ = try await repository.upsert(recipeID: "r1", memberID: "m1", rating: 5, comment: "美味しかった")

        let reviews = try await repository.fetchAll(recipeID: "r1")

        XCTAssertEqual(reviews.count, 1)
        XCTAssertEqual(reviews.first?.rating, 5)
        XCTAssertEqual(reviews.first?.comment, "美味しかった")
    }

    func testFetchAllFiltersByRecipeID() async throws {
        let repository = InMemoryReviewRepository()

        _ = try await repository.upsert(recipeID: "r1", memberID: "m1", rating: 4, comment: nil)
        _ = try await repository.upsert(recipeID: "r2", memberID: "m1", rating: 2, comment: nil)

        let reviews = try await repository.fetchAll(recipeID: "r1")

        XCTAssertEqual(reviews.count, 1)
        XCTAssertEqual(reviews.first?.recipeID, "r1")
    }
}
