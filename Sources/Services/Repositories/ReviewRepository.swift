import CloudKit
import Foundation

protocol ReviewRepository {
    func fetchAll(recipeID: String) async throws -> [Review]
    func upsert(recipeID: String, memberID: String, rating: Int, comment: String?) async throws -> Review
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
}
