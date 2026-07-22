import Foundation

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var avatarEmoji: String
    var iCloudUserRecordName: String?

    init(
        id: String = UUID().uuidString,
        displayName: String,
        avatarEmoji: String = "🙂",
        iCloudUserRecordName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.iCloudUserRecordName = iCloudUserRecordName
    }
}
