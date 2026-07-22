import CloudKit
import Foundation

extension Recipe {
    static let recordType = "Recipe"

    init?(record: CKRecord) {
        guard record.recordType == Recipe.recordType,
              let title = record["title"] as? String,
              let instructions = record["instructions"] as? String,
              let servings = record["servings"] as? Int,
              let genreRaw = record["genre"] as? String,
              let genre = Genre(rawValue: genreRaw),
              let createdByMemberID = record["createdByMemberID"] as? String,
              let createdAt = record["createdAt"] as? Date
        else { return nil }

        var ingredients: [Ingredient] = []
        if let data = record["ingredientsJSON"] as? Data,
           let decoded = try? JSONDecoder().decode([Ingredient].self, from: data) {
            ingredients = decoded
        }

        var localImageURL: URL?
        if let asset = record["photo"] as? CKAsset {
            localImageURL = asset.fileURL
        }

        var sourceURL: URL?
        if let sourceURLString = record["sourceURL"] as? String {
            sourceURL = URL(string: sourceURLString)
        }

        self.init(
            id: record.recordID.recordName,
            title: title,
            instructions: instructions,
            sourceURL: sourceURL,
            servings: servings,
            costPerServing: record["costPerServing"] as? Int,
            genre: genre,
            ingredients: ingredients,
            createdByMemberID: createdByMemberID,
            createdAt: createdAt,
            localImageURL: localImageURL
        )
    }

    func toRecord(zoneID: CKRecordZone.ID, existingRecordID: CKRecord.ID? = nil) -> CKRecord {
        let recordID = existingRecordID ?? CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: Recipe.recordType, recordID: recordID)

        record["title"] = title as CKRecordValue
        record["instructions"] = instructions as CKRecordValue
        record["servings"] = servings as CKRecordValue
        record["genre"] = genre.rawValue as CKRecordValue
        record["createdByMemberID"] = createdByMemberID as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue

        if let costPerServing {
            record["costPerServing"] = costPerServing as CKRecordValue
        }
        if let sourceURL {
            record["sourceURL"] = sourceURL.absoluteString as CKRecordValue
        }
        if let data = try? JSONEncoder().encode(ingredients) {
            record["ingredientsJSON"] = data as CKRecordValue
        }
        if let localImageURL {
            record["photo"] = CKAsset(fileURL: localImageURL)
        }

        return record
    }
}
