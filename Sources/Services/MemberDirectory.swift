import Foundation

/// メンバーID -> 表示名 の解決を行う。家族の評価・投票画面などで「家族の1人」のような
/// 匿名表示ではなく実名を出すために使う。
@MainActor
final class MemberDirectory: ObservableObject {
    @Published private(set) var displayNames: [String: String] = [:]

    private let repository: FamilyMemberRepository

    init(repository: FamilyMemberRepository) {
        self.repository = repository
    }

    func displayName(for memberID: String) -> String? {
        displayNames[memberID]
    }

    func loadAll() async {
        guard let members = try? await repository.fetchAll() else { return }
        displayNames = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.displayName) })
    }

    @discardableResult
    func setDisplayName(_ name: String, memberID: String) async -> Bool {
        guard let saved = try? await repository.upsert(FamilyMember(id: memberID, displayName: name)) else {
            return false
        }
        displayNames[saved.id] = saved.displayName
        return true
    }
}
