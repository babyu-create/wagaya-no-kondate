import XCTest
@testable import WagayaNoKondate

final class InMemoryRecipeRepositoryTests: XCTestCase {
    func testSaveWithNewIDInsertsNewRecipe() async throws {
        let repository = InMemoryRecipeRepository()

        _ = try await repository.save(Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))
        _ = try await repository.save(Recipe(title: "味噌汁", instructions: "-", servings: 2, genre: .japanese, createdByMemberID: "m1"))

        let all = try await repository.fetchAll()
        XCTAssertEqual(all.count, 2)
    }

    func testSaveWithExistingIDUpdatesInPlaceInsteadOfDuplicating() async throws {
        let repository = InMemoryRecipeRepository()
        let original = Recipe(
            id: "recipe-1",
            title: "カレー",
            instructions: "煮る",
            servings: 4,
            genre: .other,
            createdByMemberID: "m1"
        )
        _ = try await repository.save(original)

        var edited = original
        edited.title = "スパイスカレー"
        edited.servings = 5
        _ = try await repository.save(edited)

        let all = try await repository.fetchAll()

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.title, "スパイスカレー")
        XCTAssertEqual(all.first?.servings, 5)
    }

    func testDeleteRemovesRecipe() async throws {
        let repository = InMemoryRecipeRepository()
        let saved = try await repository.save(Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1"))

        try await repository.delete(id: saved.id)

        let all = try await repository.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }
}
