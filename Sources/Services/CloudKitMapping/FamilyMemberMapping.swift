import CloudKit
import Foundation

extension FamilyMember {
    static let recordType = "Member"

    init?(record: CKRecord) {
        guard record.recordType == FamilyMember.recordType,
              let displayName = record["displayName"] as? String
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            displayName: displayName,
            avatarEmoji: (record["avatarEmoji"] as? String) ?? "🙂",
            iCloudUserRecordName: record["iCloudUserRecordName"] as? String
        )
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: FamilyMember.recordType, recordID: recordID)
        record["displayName"] = displayName as CKRecordValue
        record["avatarEmoji"] = avatarEmoji as CKRecordValue
        if let iCloudUserRecordName {
            record["iCloudUserRecordName"] = iCloudUserRecordName as CKRecordValue
        }
        return record
    }
}
