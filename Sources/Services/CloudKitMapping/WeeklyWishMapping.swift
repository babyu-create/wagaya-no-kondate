import CloudKit
import Foundation

extension WeeklyWish {
    static let recordType = "WeeklyWish"

    static func upsertID(recipeID: String, memberID: String, weekOf: String) -> String {
        "\(recipeID)_\(memberID)_\(weekOf)"
    }

    init?(record: CKRecord) {
        guard record.recordType == WeeklyWish.recordType,
              let recipeID = record["recipeID"] as? String,
              let memberID = record["memberID"] as? String,
              let weekOf = record["weekOf"] as? String
        else { return nil }

        self.init(id: record.recordID.recordName, recipeID: recipeID, memberID: memberID, weekOf: weekOf)
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: WeeklyWish.recordType, recordID: recordID)
        record["recipeID"] = recipeID as CKRecordValue
        record["memberID"] = memberID as CKRecordValue
        record["weekOf"] = weekOf as CKRecordValue
        return record
    }
}
