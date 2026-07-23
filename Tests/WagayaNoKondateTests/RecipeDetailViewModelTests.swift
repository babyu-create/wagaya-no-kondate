import XCTest
@testable import WagayaNoKondate

@MainActor
final class RecipeDetailViewModelTests: XCTestCase {
    private func makeRecipe() -> Recipe {
        Recipe(id: "recipe-1", title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
    }

    func testLoadPopulatesReviewsAndComputesAverage() async throws {
        let reviewRepository = InMemoryReviewRepository()
        let recipe = makeRecipe()
        _ = try await reviewRepository.upsert(recipeID: recipe.id, memberID: "m1", rating: 5, comment: nil)
        _ = try await reviewRepository.upsert(recipeID: recipe.id, memberID: "m2", rating: 3, comment: nil)

        let viewModel = RecipeDetailViewModel(recipe: recipe, reviewRepository: reviewRepository, currentMemberID: "m1")
        await viewModel.load()

        XCTAssertEqual(viewModel.reviews.count, 2)
        XCTAssertEqual(viewModel.averageRating, 4.0)
        XCTAssertEqual(viewModel.myRating, 5)
        XCTAssertEqual(viewModel.otherReviews.map(\.memberID), ["m2"])
    }

    func testMyRatingIsZeroWhenNoReviewYet() async {
        let viewModel = RecipeDetailViewModel(recipe: makeRecipe(), reviewRepository: InMemoryReviewRepository(), currentMemberID: "m1")
        await viewModel.load()
        XCTAssertEqual(viewModel.myRating, 0)
        XCTAssertNil(viewModel.averageRating)
    }

    func testSubmitRatingAddsThenUpdatesOwnReview() async {
        let recipe = makeRecipe()
        let viewModel = RecipeDetailViewModel(recipe: recipe, reviewRepository: InMemoryReviewRepository(), currentMemberID: "m1")
        await viewModel.load()

        await viewModel.submitRating(3)
        XCTAssertEqual(viewModel.myRating, 3)
        XCTAssertEqual(viewModel.reviews.count, 1)

        await viewModel.submitRating(5)
        XCTAssertEqual(viewModel.myRating, 5)
        XCTAssertEqual(viewModel.reviews.count, 1)
    }

    func testApplyEditUpdatesRecipe() async {
        let viewModel = RecipeDetailViewModel(recipe: makeRecipe(), reviewRepository: InMemoryReviewRepository(), currentMemberID: "m1")

        var edited = viewModel.recipe
        edited.title = "スパイスカレー"
        viewModel.applyEdit(edited)

        XCTAssertEqual(viewModel.recipe.title, "スパイスカレー")
    }
}
