import XCTest
@testable import WagayaNoKondate

@MainActor
final class FridgeViewModelTests: XCTestCase {
    private func makeRecipe(title: String, genre: Genre, ingredients: [Ingredient]) -> Recipe {
        Recipe(title: title, instructions: "-", servings: 2, genre: genre, ingredients: ingredients, createdByMemberID: "m1")
    }

    func testLoadPopulatesFridgeItemsAndRecipes() async throws {
        let fridgeRepository = InMemoryFridgeItemRepository()
        let recipeRepository = InMemoryRecipeRepository()
        _ = try await fridgeRepository.save(FridgeItem(displayName: "じゃがいも", updatedByMemberID: "m1"))
        _ = try await recipeRepository.save(makeRecipe(title: "カレー", genre: .other, ingredients: []))

        let viewModel = FridgeViewModel(fridgeRepository: fridgeRepository, recipeRepository: recipeRepository, currentMemberID: "m1")
        await viewModel.load()

        XCTAssertEqual(viewModel.fridgeItems.count, 1)
        XCTAssertEqual(viewModel.recipes.count, 1)
    }

    func testMakeableAndAlmostMakeableRecipesReflectFridgeContents() async throws {
        let fridgeRepository = InMemoryFridgeItemRepository()
        let recipeRepository = InMemoryRecipeRepository()

        _ = try await recipeRepository.save(makeRecipe(
            title: "味噌汁",
            genre: .japanese,
            ingredients: [Ingredient(displayName: "豆腐", amount: "半丁")]
        ))
        _ = try await recipeRepository.save(makeRecipe(
            title: "カレー",
            genre: .other,
            ingredients: [
                Ingredient(displayName: "じゃがいも", amount: "2個"),
                Ingredient(displayName: "牛肉", amount: "200g"),
                Ingredient(displayName: "カレールー", amount: "1箱")
            ]
        ))
        _ = try await fridgeRepository.save(FridgeItem(displayName: "豆腐", updatedByMemberID: "m1"))
        _ = try await fridgeRepository.save(FridgeItem(displayName: "じゃがいも", updatedByMemberID: "m1"))

        let viewModel = FridgeViewModel(fridgeRepository: fridgeRepository, recipeRepository: recipeRepository, currentMemberID: "m1")
        await viewModel.load()

        XCTAssertEqual(viewModel.makeableRecipes.map(\.recipe.title), ["味噌汁"])
        XCTAssertEqual(viewModel.almostMakeableRecipes.map(\.recipe.title), ["カレー"])
    }

    func testAddItemInsertsAtFront() async {
        let viewModel = FridgeViewModel(
            fridgeRepository: InMemoryFridgeItemRepository(),
            recipeRepository: InMemoryRecipeRepository(),
            currentMemberID: "m1"
        )

        await viewModel.addItem(name: "たまねぎ", quantity: "2個")
        await viewModel.addItem(name: "にんじん", quantity: nil)

        XCTAssertEqual(viewModel.fridgeItems.first?.displayName, "にんじん")
        XCTAssertEqual(viewModel.fridgeItems.count, 2)
    }

    func testAddItemPreventsDuplicateByNormalizedName() async {
        let viewModel = FridgeViewModel(
            fridgeRepository: InMemoryFridgeItemRepository(),
            recipeRepository: InMemoryRecipeRepository(),
            currentMemberID: "m1"
        )

        await viewModel.addItem(name: "にんじん", quantity: "1本")
        // カタカナ・前後の空白違いは同じ材料とみなして重複追加しない。
        await viewModel.addItem(name: " ニンジン ", quantity: "2本")

        XCTAssertEqual(viewModel.fridgeItems.count, 1)
        XCTAssertEqual(viewModel.fridgeItems.first?.displayName, "にんじん")
    }

    func testAddItemIgnoresBlankName() async {
        let viewModel = FridgeViewModel(
            fridgeRepository: InMemoryFridgeItemRepository(),
            recipeRepository: InMemoryRecipeRepository(),
            currentMemberID: "m1"
        )

        await viewModel.addItem(name: "   ", quantity: nil)

        XCTAssertTrue(viewModel.fridgeItems.isEmpty)
    }

    func testDeleteRemovesItem() async throws {
        let fridgeRepository = InMemoryFridgeItemRepository()
        let viewModel = FridgeViewModel(
            fridgeRepository: fridgeRepository,
            recipeRepository: InMemoryRecipeRepository(),
            currentMemberID: "m1"
        )
        await viewModel.addItem(name: "牛乳", quantity: nil)

        await viewModel.delete(at: IndexSet(integer: 0))

        XCTAssertTrue(viewModel.fridgeItems.isEmpty)
    }

    func testKnownIngredientNamesDeduplicatesAcrossRecipes() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        _ = try await recipeRepository.save(makeRecipe(
            title: "A",
            genre: .other,
            ingredients: [Ingredient(displayName: "じゃがいも", amount: "1個")]
        ))
        _ = try await recipeRepository.save(makeRecipe(
            title: "B",
            genre: .other,
            ingredients: [Ingredient(displayName: "ジャガイモ", amount: "2個")]
        ))

        let viewModel = FridgeViewModel(
            fridgeRepository: InMemoryFridgeItemRepository(),
            recipeRepository: recipeRepository,
            currentMemberID: "m1"
        )
        await viewModel.load()

        XCTAssertEqual(viewModel.knownIngredientNames.count, 1)
    }
}
