import CloudKit
import Foundation

protocol WeeklyWishRepository {
    func fetchAll(weekOf: String) async throws -> [WeeklyWish]
    func toggle(recipeID: String, memberID: String, weekOf: String) async throws -> WeeklyWish?
    /// レシピが削除された際に、そのレシピに紐づく「今週食べたい」をすべて削除する。
    func deleteAll(recipeID: String) async throws
}

final class InMemoryWeeklyWishRepository: WeeklyWishRepository {
    private var storage: [String: WeeklyWish] = [:]

    func fetchAll(weekOf: String) async throws -> [WeeklyWish] {
        storage.values.filter { $0.weekOf == weekOf }
    }

    func toggle(recipeID: String, memberID: String, weekOf: String) async throws -> WeeklyWish? {
        let id = WeeklyWish.upsertID(recipeID: recipeID, memberID: memberID, weekOf: weekOf)
        if storage[id] != nil {
            storage[id] = nil
            return nil
        }
        let wish = WeeklyWish(id: id, recipeID: recipeID, memberID: memberID, weekOf: weekOf)
        storage[id] = wish
        return wish
    }

    func deleteAll(recipeID: String) async throws {
        storage = storage.filter { $0.value.recipeID != recipeID }
    }
}

final class CloudKitWeeklyWishRepository: WeeklyWishRepository {
    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func fetchAll(weekOf: String) async throws -> [WeeklyWish] {
        let target = try await service.resolveWritableTarget()
        let predicate = NSPredicate(format: "weekOf == %@", weekOf)
        let query = CKQuery(recordType: WeeklyWish.recordType, predicate: predicate)
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return WeeklyWish(record: record)
        }
    }

    func toggle(recipeID: String, memberID: String, weekOf: String) async throws -> WeeklyWish? {
        let target = try await service.resolveWritableTarget()
        let id = WeeklyWish.upsertID(recipeID: recipeID, memberID: memberID, weekOf: weekOf)
        let recordID = CKRecord.ID(recordName: id, zoneID: target.zoneID)

        if let existing = try? await target.database.record(for: recordID), existing.recordType == WeeklyWish.recordType {
            _ = try await target.database.deleteRecord(withID: recordID)
            return nil
        }

        let wish = WeeklyWish(id: id, recipeID: recipeID, memberID: memberID, weekOf: weekOf)
        let record = wish.toRecord(zoneID: target.zoneID)
        let saved = try await target.database.save(record)
        return WeeklyWish(record: saved)
    }

    func deleteAll(recipeID: String) async throws {
        let target = try await service.resolveWritableTarget()
        let predicate = NSPredicate(format: "recipeID == %@", recipeID)
        let query = CKQuery(recordType: WeeklyWish.recordType, predicate: predicate)
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        for (recordID, _) in matchResults {
            _ = try? await target.database.deleteRecord(withID: recordID)
        }
    }
}
