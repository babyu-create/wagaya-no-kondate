import CloudKit
import Foundation

protocol ReviewRepository {
    func fetchAll(recipeID: String) async throws -> [Review]
    func upsert(recipeID: String, memberID: String, rating: Int, comment: String?) async throws -> Review
    /// レシピが削除された際に、そのレシピに紐づくレビューをすべて削除する。
    func deleteAll(recipeID: String) async throws
}

final class InMemoryReviewRepository: ReviewRepository {
    private var storage: [String: Review] = [:]

    init(seed: [Review] = []) {
        for review in seed {
            storage[review.id] = review
        }
    }

    func fetchAll(recipeID: String) async throws -> [Review] {
        storage.values.filter { $0.recipeID == recipeID }
    }

    func upsert(recipeID: String, memberID: String, rating: Int, comment: String?) async throws -> Review {
        let id = Review.upsertID(recipeID: recipeID, memberID: memberID)
        let review = Review(id: id, recipeID: recipeID, memberID: memberID, rating: rating, comment: comment)
        storage[id] = review
        return review
    }

    func deleteAll(recipeID: String) async throws {
        storage = storage.filter { $0.value.recipeID != recipeID }
    }
}

final class CloudKitReviewRepository: ReviewRepository {
    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func fetchAll(recipeID: String) async throws -> [Review] {
        let target = try await service.resolveWritableTarget()
        let predicate = NSPredicate(format: "recipeID == %@", recipeID)
        let query = CKQuery(recordType: Review.recordType, predicate: predicate)
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return Review(record: record)
        }
    }

    func upsert(recipeID: String, memberID: String, rating: Int, comment: String?) async throws -> Review {
        let target = try await service.resolveWritableTarget()
        let id = Review.upsertID(recipeID: recipeID, memberID: memberID)
        let review = Review(id: id, recipeID: recipeID, memberID: memberID, rating: rating, comment: comment)
        let record = review.toRecord(zoneID: target.zoneID)
        let saved = try await target.database.save(record)
        guard let savedReview = Review(record: saved) else {
            throw CloudKitServiceError.familyZoneNotFound
        }
        return savedReview
    }

    func deleteAll(recipeID: String) async throws {
        let reviews = try await fetchAll(recipeID: recipeID)
        guard !reviews.isEmpty else { return }
        let target = try await service.resolveWritableTarget()
        for review in reviews {
            let recordID = CKRecord.ID(recordName: review.id, zoneID: target.zoneID)
            _ = try? await target.database.deleteRecord(withID: recordID)
        }
    }
}
