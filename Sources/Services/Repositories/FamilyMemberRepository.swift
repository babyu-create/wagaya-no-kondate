import CloudKit
import Foundation

protocol FamilyMemberRepository {
    func fetchAll() async throws -> [FamilyMember]
    func upsert(_ member: FamilyMember) async throws -> FamilyMember
}

final class InMemoryFamilyMemberRepository: FamilyMemberRepository {
    private var storage: [String: FamilyMember] = [:]

    init(seed: [FamilyMember] = []) {
        for member in seed {
            storage[member.id] = member
        }
    }

    func fetchAll() async throws -> [FamilyMember] {
        Array(storage.values)
    }

    func upsert(_ member: FamilyMember) async throws -> FamilyMember {
        storage[member.id] = member
        return member
    }
}

final class CloudKitFamilyMemberRepository: FamilyMemberRepository {
    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func fetchAll() async throws -> [FamilyMember] {
        let target = try await service.resolveWritableTarget()
        let query = CKQuery(recordType: FamilyMember.recordType, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return FamilyMember(record: record)
        }
    }

    func upsert(_ member: FamilyMember) async throws -> FamilyMember {
        let target = try await service.resolveWritableTarget()
        let record = member.toRecord(zoneID: target.zoneID)
        // 名前・アイコンの変更（同じmemberID）を上書きできるようにする。
        let saved = try await service.upsert(record, in: target.database)
        guard let savedMember = FamilyMember(record: saved) else {
            throw CloudKitServiceError.saveFailed
        }
        return savedMember
    }
}
