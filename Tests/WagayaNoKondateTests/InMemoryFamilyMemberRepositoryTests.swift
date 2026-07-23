import XCTest
@testable import WagayaNoKondate

final class InMemoryFamilyMemberRepositoryTests: XCTestCase {
    func testUpsertThenFetchAll() async throws {
        let repository = InMemoryFamilyMemberRepository()

        _ = try await repository.upsert(FamilyMember(id: "member-1", displayName: "お母さん"))
        _ = try await repository.upsert(FamilyMember(id: "member-2", displayName: "お父さん"))

        let members = try await repository.fetchAll()

        XCTAssertEqual(members.count, 2)
    }

    func testUpsertOverwritesExistingMember() async throws {
        let repository = InMemoryFamilyMemberRepository()

        _ = try await repository.upsert(FamilyMember(id: "member-1", displayName: "旧名前"))
        _ = try await repository.upsert(FamilyMember(id: "member-1", displayName: "新しい名前"))

        let members = try await repository.fetchAll()

        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(members.first?.displayName, "新しい名前")
    }
}
