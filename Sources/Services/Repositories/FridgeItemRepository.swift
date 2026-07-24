import CloudKit
import Foundation

protocol FridgeItemRepository {
    func fetchAll() async throws -> [FridgeItem]
    func save(_ item: FridgeItem) async throws -> FridgeItem
    func delete(id: String) async throws
}

final class InMemoryFridgeItemRepository: FridgeItemRepository {
    private var storage: [String: FridgeItem] = [:]

    init(seed: [FridgeItem] = []) {
        for item in seed {
            storage[item.id] = item
        }
    }

    func fetchAll() async throws -> [FridgeItem] {
        Array(storage.values).sorted { $0.updatedAt > $1.updatedAt }
    }

    func save(_ item: FridgeItem) async throws -> FridgeItem {
        storage[item.id] = item
        return item
    }

    func delete(id: String) async throws {
        storage[id] = nil
    }
}

final class CloudKitFridgeItemRepository: FridgeItemRepository {
    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func fetchAll() async throws -> [FridgeItem] {
        let target = try await service.resolveWritableTarget()
        let query = CKQuery(recordType: FridgeItem.recordType, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return FridgeItem(record: record)
        }
    }

    func save(_ item: FridgeItem) async throws -> FridgeItem {
        let target = try await service.resolveWritableTarget()
        let record = item.toRecord(zoneID: target.zoneID)
        let saved = try await service.upsert(record, in: target.database)
        guard let savedItem = FridgeItem(record: saved) else {
            throw CloudKitServiceError.saveFailed
        }
        return savedItem
    }

    func delete(id: String) async throws {
        let target = try await service.resolveWritableTarget()
        let recordID = CKRecord.ID(recordName: id, zoneID: target.zoneID)
        _ = try await target.database.deleteRecord(withID: recordID)
    }
}
