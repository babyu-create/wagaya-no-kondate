import CloudKit
import Foundation

protocol RecipeRepository {
    func fetchAll() async throws -> [Recipe]
    func save(_ recipe: Recipe) async throws -> Recipe
    func delete(id: String) async throws
}

final class InMemoryRecipeRepository: RecipeRepository {
    private var storage: [String: Recipe] = [:]

    init(seed: [Recipe] = []) {
        for recipe in seed {
            storage[recipe.id] = recipe
        }
    }

    func fetchAll() async throws -> [Recipe] {
        Array(storage.values).sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ recipe: Recipe) async throws -> Recipe {
        storage[recipe.id] = recipe
        return recipe
    }

    func delete(id: String) async throws {
        storage[id] = nil
    }
}

final class CloudKitRecipeRepository: RecipeRepository {
    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func fetchAll() async throws -> [Recipe] {
        let target = try await service.resolveWritableTarget()
        let query = CKQuery(recordType: Recipe.recordType, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return Recipe(record: record)
        }
    }

    func save(_ recipe: Recipe) async throws -> Recipe {
        let target = try await service.resolveWritableTarget()
        let record = recipe.toRecord(zoneID: target.zoneID)
        let saved = try await service.upsert(record, in: target.database)
        guard let savedRecipe = Recipe(record: saved) else {
            throw CloudKitServiceError.saveFailed
        }
        return savedRecipe
    }

    func delete(id: String) async throws {
        let target = try await service.resolveWritableTarget()
        let recordID = CKRecord.ID(recordName: id, zoneID: target.zoneID)
        _ = try await target.database.deleteRecord(withID: recordID)
    }
}
