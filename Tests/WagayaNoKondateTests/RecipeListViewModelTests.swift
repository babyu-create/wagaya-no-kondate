import XCTest
@testable import WagayaNoKondate

@MainActor
final class RecipeListViewModelTests: XCTestCase {
    func testLoadPopulatesRecipes() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        _ = try await recipeRepository.save(Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))

        let viewModel = RecipeListViewModel(
            repository: recipeRepository,
            reviewRepository: InMemoryReviewRepository(),
            weeklyWishRepository: InMemoryWeeklyWishRepository()
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.recipes.count, 1)
    }

    func testInsertAddsRecipeToFront() {
        let viewModel = RecipeListViewModel(
            repository: InMemoryRecipeRepository(),
            reviewRepository: InMemoryReviewRepository(),
            weeklyWishRepository: InMemoryWeeklyWishRepository()
        )

        viewModel.insert(Recipe(title: "既存", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))
        viewModel.insert(Recipe(title: "新規", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))

        XCTAssertEqual(viewModel.recipes.first?.title, "新規")
    }

    func testDeleteRemovesRecipeAndCascadesReviewsAndWishes() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let reviewRepository = InMemoryReviewRepository()
        let weeklyWishRepository = InMemoryWeeklyWishRepository()

        let saved = try await recipeRepository.save(
            Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        _ = try await reviewRepository.upsert(recipeID: saved.id, memberID: "m1", rating: 5, comment: nil)
        _ = try await weeklyWishRepository.toggle(recipeID: saved.id, memberID: "m1", weekOf: "2026-W30")

        let viewModel = RecipeListViewModel(
            repository: recipeRepository,
            reviewRepository: reviewRepository,
            weeklyWishRepository: weeklyWishRepository
        )
        await viewModel.load()

        await viewModel.delete(at: IndexSet(integer: 0))

        XCTAssertTrue(viewModel.recipes.isEmpty)
        let remainingReviews = try await reviewRepository.fetchAll(recipeID: saved.id)
        XCTAssertTrue(remainingReviews.isEmpty)
        let remainingWishes = try await weeklyWishRepository.fetchAll(weekOf: "2026-W30")
        XCTAssertTrue(remainingWishes.isEmpty)
    }
}
