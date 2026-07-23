import XCTest
@testable import WagayaNoKondate

@MainActor
final class MemberDirectoryTests: XCTestCase {
    func testDisplayNameIsNilBeforeLoading() {
        let directory = MemberDirectory(repository: InMemoryFamilyMemberRepository())
        XCTAssertNil(directory.displayName(for: "member-1"))
    }

    func testLoadAllPopulatesDisplayNames() async {
        let repository = InMemoryFamilyMemberRepository(seed: [
            FamilyMember(id: "member-1", displayName: "お父さん")
        ])
        let directory = MemberDirectory(repository: repository)

        await directory.loadAll()

        XCTAssertEqual(directory.displayName(for: "member-1"), "お父さん")
    }

    func testSetDisplayNameUpdatesImmediately() async {
        let directory = MemberDirectory(repository: InMemoryFamilyMemberRepository())

        let success = await directory.setDisplayName("たろう", memberID: "member-2")

        XCTAssertTrue(success)
        XCTAssertEqual(directory.displayName(for: "member-2"), "たろう")
    }
}
