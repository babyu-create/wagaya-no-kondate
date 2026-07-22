import CloudKit
import Foundation

extension Review {
    static let recordType = "Review"

    /// レシピ×メンバーごとに1件だけ存在させるための決定的ID（同じ組で再保存すると上書きされる）。
    static func upsertID(recipeID: String, memberID: String) -> String {
        "\(recipeID)_\(memberID)"
    }

    init?(record: CKRecord) {
        guard record.recordType == Review.recordType,
              let recipeID = record["recipeID"] as? String,
              let memberID = record["memberID"] as? String,
              let rating = record["rating"] as? Int,
              let updatedAt = record["updatedAt"] as? Date
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            recipeID: recipeID,
            memberID: memberID,
            rating: rating,
            comment: record["comment"] as? String,
            updatedAt: updatedAt
        )
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: Review.recordType, recordID: recordID)
        record["recipeID"] = recipeID as CKRecordValue
        record["memberID"] = memberID as CKRecordValue
        record["rating"] = rating as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        if let comment {
            record["comment"] = comment as CKRecordValue
        }
        return record
    }
}
