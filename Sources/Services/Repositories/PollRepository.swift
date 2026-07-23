import CloudKit
import Foundation

protocol PollRepository {
    func fetchActivePoll() async throws -> (poll: Poll, options: [PollOption])?
    func fetchVotes(pollID: String) async throws -> [Vote]
    func createPoll(
        type: PollType,
        genre: Genre?,
        deadline: Date?,
        recipeIDs: [String],
        createdByMemberID: String
    ) async throws -> (poll: Poll, options: [PollOption])
    func vote(pollID: String, pollOptionID: String, memberID: String) async throws -> Vote
    func closePoll(_ poll: Poll) async throws
}

final class InMemoryPollRepository: PollRepository {
    private var polls: [String: Poll] = [:]
    private var optionsByPoll: [String: [PollOption]] = [:]
    private var votes: [String: Vote] = [:]

    func fetchActivePoll() async throws -> (poll: Poll, options: [PollOption])? {
        guard let poll = polls.values
            .filter({ $0.status == .open })
            .sorted(by: { $0.date > $1.date })
            .first
        else {
            return nil
        }
        return (poll, optionsByPoll[poll.id] ?? [])
    }

    func fetchVotes(pollID: String) async throws -> [Vote] {
        votes.values.filter { $0.pollID == pollID }
    }

    func createPoll(
        type: PollType,
        genre: Genre?,
        deadline: Date?,
        recipeIDs: [String],
        createdByMemberID: String
    ) async throws -> (poll: Poll, options: [PollOption]) {
        let poll = Poll(type: type, genre: genre, deadline: deadline, createdByMemberID: createdByMemberID)
        let options = recipeIDs.map { PollOption(pollID: poll.id, recipeID: $0) }
        polls[poll.id] = poll
        optionsByPoll[poll.id] = options
        return (poll, options)
    }

    func vote(pollID: String, pollOptionID: String, memberID: String) async throws -> Vote {
        let id = Vote.upsertID(pollID: pollID, memberID: memberID)
        let vote = Vote(id: id, pollID: pollID, pollOptionID: pollOptionID, memberID: memberID)
        votes[id] = vote
        return vote
    }

    func closePoll(_ poll: Poll) async throws {
        var updated = poll
        updated.status = .closed
        polls[poll.id] = updated
    }
}

final class CloudKitPollRepository: PollRepository {
    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func fetchActivePoll() async throws -> (poll: Poll, options: [PollOption])? {
        let target = try await service.resolveWritableTarget()
        let predicate = NSPredicate(format: "status == %@", PollStatus.open.rawValue)
        let query = CKQuery(recordType: Poll.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let (matchResults, _) = try await target.database.records(
            matching: query,
            inZoneWith: target.zoneID,
            resultsLimit: 1
        )

        guard let first = matchResults.first,
              let record = try? first.1.get(),
              let poll = Poll(record: record)
        else {
            return nil
        }

        let options = try await fetchOptions(pollID: poll.id, target: target)
        return (poll, options)
    }

    private func fetchOptions(
        pollID: String,
        target: (database: CKDatabase, zoneID: CKRecordZone.ID)
    ) async throws -> [PollOption] {
        let predicate = NSPredicate(format: "pollID == %@", pollID)
        let query = CKQuery(recordType: PollOption.recordType, predicate: predicate)
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return PollOption(record: record)
        }
    }

    func fetchVotes(pollID: String) async throws -> [Vote] {
        let target = try await service.resolveWritableTarget()
        let predicate = NSPredicate(format: "pollID == %@", pollID)
        let query = CKQuery(recordType: Vote.recordType, predicate: predicate)
        let (matchResults, _) = try await target.database.records(matching: query, inZoneWith: target.zoneID)
        return matchResults.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return Vote(record: record)
        }
    }

    func createPoll(
        type: PollType,
        genre: Genre?,
        deadline: Date?,
        recipeIDs: [String],
        createdByMemberID: String
    ) async throws -> (poll: Poll, options: [PollOption]) {
        let target = try await service.resolveWritableTarget()
        let poll = Poll(type: type, genre: genre, deadline: deadline, createdByMemberID: createdByMemberID)
        let pollRecord = poll.toRecord(zoneID: target.zoneID)
        let savedPollRecord = try await target.database.save(pollRecord)
        guard let savedPoll = Poll(record: savedPollRecord) else {
            throw CloudKitServiceError.familyZoneNotFound
        }

        var savedOptions: [PollOption] = []
        for recipeID in recipeIDs {
            let option = PollOption(pollID: savedPoll.id, recipeID: recipeID)
            let record = option.toRecord(zoneID: target.zoneID)
            let saved = try await target.database.save(record)
            if let savedOption = PollOption(record: saved) {
                savedOptions.append(savedOption)
            }
        }

        return (savedPoll, savedOptions)
    }

    func vote(pollID: String, pollOptionID: String, memberID: String) async throws -> Vote {
        let target = try await service.resolveWritableTarget()
        let id = Vote.upsertID(pollID: pollID, memberID: memberID)
        let vote = Vote(id: id, pollID: pollID, pollOptionID: pollOptionID, memberID: memberID)
        let record = vote.toRecord(zoneID: target.zoneID)
        let saved = try await target.database.save(record)
        guard let savedVote = Vote(record: saved) else {
            throw CloudKitServiceError.familyZoneNotFound
        }
        return savedVote
    }

    func closePoll(_ poll: Poll) async throws {
        let target = try await service.resolveWritableTarget()
        var updated = poll
        updated.status = .closed
        let record = updated.toRecord(zoneID: target.zoneID)
        _ = try await target.database.save(record)
    }
}
