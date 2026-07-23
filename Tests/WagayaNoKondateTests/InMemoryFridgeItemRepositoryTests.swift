import XCTest
@testable import WagayaNoKondate

final class InMemoryFridgeItemRepositoryTests: XCTestCase {
    func testSaveAndFetchAll() async throws {
        let repository = InMemoryFridgeItemRepository()

        _ = try await repository.save(FridgeItem(displayName: "牛乳", updatedByMemberID: "m1"))
        _ = try await repository.save(FridgeItem(displayName: "卵", updatedByMemberID: "m1"))

        let items = try await repository.fetchAll()

        XCTAssertEqual(items.count, 2)
    }

    func testDeleteRemovesItem() async throws {
        let repository = InMemoryFridgeItemRepository()
        let saved = try await repository.save(FridgeItem(displayName: "牛乳", updatedByMemberID: "m1"))

        try await repository.delete(id: saved.id)

        let items = try await repository.fetchAll()
        XCTAssertTrue(items.isEmpty)
    }
}
