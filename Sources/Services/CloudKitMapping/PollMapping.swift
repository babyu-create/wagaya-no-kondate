import CloudKit
import Foundation

extension Poll {
    static let recordType = "Poll"

    init?(record: CKRecord) {
        guard record.recordType == Poll.recordType,
              let date = record["date"] as? Date,
              let typeRaw = record["type"] as? String,
              let type = PollType(rawValue: typeRaw),
              let statusRaw = record["status"] as? String,
              let status = PollStatus(rawValue: statusRaw),
              let createdByMemberID = record["createdByMemberID"] as? String
        else { return nil }

        var genre: Genre?
        if let genreRaw = record["genre"] as? String {
            genre = Genre(rawValue: genreRaw)
        }

        self.init(
            id: record.recordID.recordName,
            date: date,
            type: type,
            genre: genre,
            status: status,
            deadline: record["deadline"] as? Date,
            createdByMemberID: createdByMemberID
        )
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: Poll.recordType, recordID: recordID)
        record["date"] = date as CKRecordValue
        record["type"] = type.rawValue as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["createdByMemberID"] = createdByMemberID as CKRecordValue
        if let genre {
            record["genre"] = genre.rawValue as CKRecordValue
        }
        if let deadline {
            record["deadline"] = deadline as CKRecordValue
        }
        return record
    }
}

extension PollOption {
    static let recordType = "PollOption"

    init?(record: CKRecord) {
        guard record.recordType == PollOption.recordType,
              let pollID = record["pollID"] as? String,
              let recipeID = record["recipeID"] as? String
        else { return nil }

        self.init(id: record.recordID.recordName, pollID: pollID, recipeID: recipeID)
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: PollOption.recordType, recordID: recordID)
        record["pollID"] = pollID as CKRecordValue
        record["recipeID"] = recipeID as CKRecordValue
        return record
    }
}

extension Vote {
    static let recordType = "Vote"

    static func upsertID(pollID: String, memberID: String) -> String {
        "\(pollID)_\(memberID)"
    }

    init?(record: CKRecord) {
        guard record.recordType == Vote.recordType,
              let pollID = record["pollID"] as? String,
              let pollOptionID = record["pollOptionID"] as? String,
              let memberID = record["memberID"] as? String,
              let votedAt = record["votedAt"] as? Date
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            pollID: pollID,
            pollOptionID: pollOptionID,
            memberID: memberID,
            votedAt: votedAt
        )
    }

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: Vote.recordType, recordID: recordID)
        record["pollID"] = pollID as CKRecordValue
        record["pollOptionID"] = pollOptionID as CKRecordValue
        record["memberID"] = memberID as CKRecordValue
        record["votedAt"] = votedAt as CKRecordValue
        return record
    }
}
