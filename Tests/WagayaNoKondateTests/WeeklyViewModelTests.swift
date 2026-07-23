import XCTest
@testable import WagayaNoKondate

@MainActor
final class WeeklyViewModelTests: XCTestCase {
    private func makeRecipe(title: String) -> Recipe {
        Recipe(title: title, instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
    }

    func testLoadPopulatesRecipesAndWishes() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let weeklyWishRepository = InMemoryWeeklyWishRepository()
        let recipe = try await recipeRepository.save(makeRecipe(title: "カレー"))
        _ = try await weeklyWishRepository.toggle(recipeID: recipe.id, memberID: "m1", weekOf: "2026-W30")

        let viewModel = WeeklyViewModel(
            recipeRepository: recipeRepository,
            weeklyWishRepository: weeklyWishRepository,
            currentMemberID: "m1",
            weekOf: "2026-W30"
        )
        await viewModel.load()

        XCTAssertEqual(viewModel.recipes.count, 1)
        XCTAssertEqual(viewModel.wishes.count, 1)
    }

    func testToggleWishAddsThenRemoves() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let recipe = try await recipeRepository.save(makeRecipe(title: "カレー"))

        let viewModel = WeeklyViewModel(
            recipeRepository: recipeRepository,
            weeklyWishRepository: InMemoryWeeklyWishRepository(),
            currentMemberID: "m1",
            weekOf: "2026-W30"
        )
        await viewModel.load()

        await viewModel.toggleWish(for: recipe)
        XCTAssertTrue(viewModel.isWishedByMe(recipe.id))
        XCTAssertEqual(viewModel.wishedRecipes.map(\.id), [recipe.id])

        await viewModel.toggleWish(for: recipe)
        XCTAssertFalse(viewModel.isWishedByMe(recipe.id))
        XCTAssertTrue(viewModel.wishedRecipes.isEmpty)
    }

    func testWishCountReflectsMultipleMembers() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let weeklyWishRepository = InMemoryWeeklyWishRepository()
        let recipe = try await recipeRepository.save(makeRecipe(title: "カレー"))
        _ = try await weeklyWishRepository.toggle(recipeID: recipe.id, memberID: "m1", weekOf: "2026-W30")
        _ = try await weeklyWishRepository.toggle(recipeID: recipe.id, memberID: "m2", weekOf: "2026-W30")

        let viewModel = WeeklyViewModel(
            recipeRepository: recipeRepository,
            weeklyWishRepository: weeklyWishRepository,
            currentMemberID: "m1",
            weekOf: "2026-W30"
        )
        await viewModel.load()

        XCTAssertEqual(viewModel.wishCount(for: recipe.id), 2)
    }
}
