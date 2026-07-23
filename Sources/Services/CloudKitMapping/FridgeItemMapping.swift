import CloudKit
import Foundation

extension FridgeItem {
    static let recordType = "FridgeItem"

    init?(record: CKRecord) {
        guard record.recordType == FridgeItem.recordType,
              let displayName = record["displayName"] as? String,
              let updatedByMemberID = record["updatedByMemberID"] as? String,
              let updatedAt = record["updatedAt"] as? Date
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            displayName: displayName,
            quantity: record["quantity"] as? String,
            updatedByMemberID: updatedByMemberID,
            updatedAt: updatedAt
        )
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: FridgeItem.recordType, recordID: recordID)
        record["displayName"] = displayName as CKRecordValue
        record["updatedByMemberID"] = updatedByMemberID as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        if let quantity {
            record["quantity"] = quantity as CKRecordValue
        }
        return record
    }
}
