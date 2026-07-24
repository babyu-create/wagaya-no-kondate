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

    func testAvatarEmojiIsNilBeforeLoading() {
        let directory = MemberDirectory(repository: InMemoryFamilyMemberRepository())
        XCTAssertNil(directory.avatarEmoji(for: "member-1"))
    }

    func testLoadAllPopulatesAvatarEmoji() async {
        let repository = InMemoryFamilyMemberRepository(seed: [
            FamilyMember(id: "member-1", displayName: "お父さん", avatarEmoji: "😎")
        ])
        let directory = MemberDirectory(repository: repository)

        await directory.loadAll()

        XCTAssertEqual(directory.avatarEmoji(for: "member-1"), "😎")
    }

    func testSetAvatarEmojiUpdatesExistingMember() async {
        let repository = InMemoryFamilyMemberRepository(seed: [
            FamilyMember(id: "member-1", displayName: "お父さん")
        ])
        let directory = MemberDirectory(repository: repository)
        await directory.loadAll()

        let success = await directory.setAvatarEmoji("🐻", memberID: "member-1")

        XCTAssertTrue(success)
        XCTAssertEqual(directory.avatarEmoji(for: "member-1"), "🐻")
        XCTAssertEqual(directory.displayName(for: "member-1"), "お父さん")
    }

    func testSetAvatarEmojiFailsForUnknownMember() async {
        let directory = MemberDirectory(repository: InMemoryFamilyMemberRepository())

        let success = await directory.setAvatarEmoji("🐻", memberID: "unknown")

        XCTAssertFalse(success)
    }

    func testSetDisplayNamePreservesExistingAvatarEmoji() async {
        let repository = InMemoryFamilyMemberRepository(seed: [
            FamilyMember(id: "member-1", displayName: "お父さん", avatarEmoji: "😎")
        ])
        let directory = MemberDirectory(repository: repository)
        await directory.loadAll()

        await directory.setDisplayName("パパ", memberID: "member-1")

        XCTAssertEqual(directory.displayName(for: "member-1"), "パパ")
        XCTAssertEqual(directory.avatarEmoji(for: "member-1"), "😎")
    }

    func testAllMembersSortedByDisplayName() async {
        let repository = InMemoryFamilyMemberRepository(seed: [
            FamilyMember(id: "member-1", displayName: "たろう"),
            FamilyMember(id: "member-2", displayName: "お母さん")
        ])
        let directory = MemberDirectory(repository: repository)

        await directory.loadAll()

        XCTAssertEqual(directory.allMembers.map(\.displayName), ["お母さん", "たろう"])
    }
}
