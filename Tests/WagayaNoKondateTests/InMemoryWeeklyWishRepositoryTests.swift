import XCTest
@testable import WagayaNoKondate

final class InMemoryWeeklyWishRepositoryTests: XCTestCase {
    func testToggleAddsThenRemovesWish() async throws {
        let repository = InMemoryWeeklyWishRepository()

        let added = try await repository.toggle(recipeID: "r1", memberID: "m1", weekOf: "2026-W30")
        XCTAssertNotNil(added)

        var wishes = try await repository.fetchAll(weekOf: "2026-W30")
        XCTAssertEqual(wishes.count, 1)

        let removed = try await repository.toggle(recipeID: "r1", memberID: "m1", weekOf: "2026-W30")
        XCTAssertNil(removed)

        wishes = try await repository.fetchAll(weekOf: "2026-W30")
        XCTAssertTrue(wishes.isEmpty)
    }

    func testFetchAllFiltersByWeek() async throws {
        let repository = InMemoryWeeklyWishRepository()

        _ = try await repository.toggle(recipeID: "r1", memberID: "m1", weekOf: "2026-W30")
        _ = try await repository.toggle(recipeID: "r2", memberID: "m1", weekOf: "2026-W31")

        let currentWeek = try await repository.fetchAll(weekOf: "2026-W30")

        XCTAssertEqual(currentWeek.count, 1)
        XCTAssertEqual(currentWeek.first?.recipeID, "r1")
    }
}
