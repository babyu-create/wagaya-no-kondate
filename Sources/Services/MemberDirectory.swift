import Foundation

/// メンバーID -> FamilyMember の解決を行う。家族の評価・投票画面などで「家族の1人」のような
/// 匿名表示ではなく実名・アイコンを出すために使う。
@MainActor
final class MemberDirectory: ObservableObject {
    @Published private(set) var members: [String: FamilyMember] = [:]

    private let repository: FamilyMemberRepository

    init(repository: FamilyMemberRepository) {
        self.repository = repository
    }

    /// 表示名の昇順で並んだ全メンバー一覧。
    var allMembers: [FamilyMember] {
        members.values.sorted { $0.displayName < $1.displayName }
    }

    func displayName(for memberID: String) -> String? {
        members[memberID]?.displayName
    }

    func avatarEmoji(for memberID: String) -> String? {
        members[memberID]?.avatarEmoji
    }

    func loadAll() async {
        guard let fetched = try? await repository.fetchAll() else { return }
        members = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
    }

    @discardableResult
    func setDisplayName(_ name: String, memberID: String) async -> Bool {
        var member = members[memberID] ?? FamilyMember(id: memberID, displayName: name)
        member.displayName = name
        return await save(member)
    }

    @discardableResult
    func setAvatarEmoji(_ emoji: String, memberID: String) async -> Bool {
        guard var member = members[memberID] else { return false }
        member.avatarEmoji = emoji
        return await save(member)
    }

    @discardableResult
    private func save(_ member: FamilyMember) async -> Bool {
        guard let saved = try? await repository.upsert(member) else { return false }
        members[saved.id] = saved
        return true
    }
}
