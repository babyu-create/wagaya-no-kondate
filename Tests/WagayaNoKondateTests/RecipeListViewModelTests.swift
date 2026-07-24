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

    func testLoadComputesAverageRatingsPerRecipe() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let reviewRepository = InMemoryReviewRepository()
        let curry = try await recipeRepository.save(
            Recipe(id: "curry", title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        let soup = try await recipeRepository.save(
            Recipe(id: "soup", title: "味噌汁", instructions: "-", servings: 2, genre: .japanese, createdByMemberID: "m1")
        )
        _ = try await reviewRepository.upsert(recipeID: curry.id, memberID: "m1", rating: 5, comment: nil)
        _ = try await reviewRepository.upsert(recipeID: curry.id, memberID: "m2", rating: 3, comment: nil)
        // soup にはレビューなし → 平均もなし

        let viewModel = RecipeListViewModel(
            repository: recipeRepository,
            reviewRepository: reviewRepository,
            weeklyWishRepository: InMemoryWeeklyWishRepository()
        )
        await viewModel.load()

        XCTAssertEqual(viewModel.averageRating(for: curry.id), 4.0)
        XCTAssertNil(viewModel.averageRating(for: soup.id))
    }

    func testComputeAveragesIgnoresReviewsForUnknownRecipe() {
        let recipes = [
            Recipe(id: "r1", title: "A", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        ]
        let reviews = [
            Review(recipeID: "r1", memberID: "m1", rating: 4),
            Review(recipeID: "other", memberID: "m1", rating: 1)
        ]

        let averages = RecipeListViewModel.computeAverages(recipes: recipes, reviews: reviews)

        XCTAssertEqual(averages, ["r1": 4.0])
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

    func testUpdateReplacesMatchingRecipeInPlace() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let saved = try await recipeRepository.save(
            Recipe(id: "r1", title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        let viewModel = RecipeListViewModel(
            repository: recipeRepository,
            reviewRepository: InMemoryReviewRepository(),
            weeklyWishRepository: InMemoryWeeklyWishRepository()
        )
        await viewModel.load()

        var edited = saved
        edited.title = "スパイスカレー"
        viewModel.update(edited)

        XCTAssertEqual(viewModel.recipes.count, 1)
        XCTAssertEqual(viewModel.recipes.first?.title, "スパイスカレー")
    }

    func testUpdateIgnoresRecipeNotInList() {
        let viewModel = RecipeListViewModel(
            repository: InMemoryRecipeRepository(),
            reviewRepository: InMemoryReviewRepository(),
            weeklyWishRepository: InMemoryWeeklyWishRepository()
        )
        viewModel.insert(Recipe(id: "r1", title: "既存", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))

        viewModel.update(Recipe(id: "r2", title: "無関係", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))

        XCTAssertEqual(viewModel.recipes.count, 1)
        XCTAssertEqual(viewModel.recipes.first?.title, "既存")
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
