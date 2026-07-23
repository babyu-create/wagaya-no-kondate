import XCTest
@testable import WagayaNoKondate

final class InMemoryPollRepositoryTests: XCTestCase {
    func testCreatePollThenVoteThenTally() async throws {
        let repository = InMemoryPollRepository()

        let created = try await repository.createPoll(
            type: .curated,
            genre: nil,
            deadline: nil,
            recipeIDs: ["r1", "r2"],
            createdByMemberID: "m1"
        )

        XCTAssertEqual(created.options.count, 2)

        let optionForR1 = try XCTUnwrap(created.options.first { $0.recipeID == "r1" })
        _ = try await repository.vote(pollID: created.poll.id, pollOptionID: optionForR1.id, memberID: "m1")
        _ = try await repository.vote(pollID: created.poll.id, pollOptionID: optionForR1.id, memberID: "m2")

        let votes = try await repository.fetchVotes(pollID: created.poll.id)
        let tally = VoteTally.tally(options: created.options, votes: votes)

        XCTAssertEqual(tally.first?.recipeID, "r1")
        XCTAssertEqual(tally.first?.count, 2)
    }

    func testVoteIsUpsertedWhenMemberVotesAgain() async throws {
        let repository = InMemoryPollRepository()
        let created = try await repository.createPoll(
            type: .curated,
            genre: nil,
            deadline: nil,
            recipeIDs: ["r1", "r2"],
            createdByMemberID: "m1"
        )
        let option1 = try XCTUnwrap(created.options.first { $0.recipeID == "r1" })
        let option2 = try XCTUnwrap(created.options.first { $0.recipeID == "r2" })

        _ = try await repository.vote(pollID: created.poll.id, pollOptionID: option1.id, memberID: "m1")
        _ = try await repository.vote(pollID: created.poll.id, pollOptionID: option2.id, memberID: "m1")

        let votes = try await repository.fetchVotes(pollID: created.poll.id)

        XCTAssertEqual(votes.count, 1)
        XCTAssertEqual(votes.first?.pollOptionID, option2.id)
    }

    func testFetchActivePollReturnsNilWhenNoneOpen() async throws {
        let repository = InMemoryPollRepository()
        let created = try await repository.createPoll(
            type: .curated,
            genre: nil,
            deadline: nil,
            recipeIDs: ["r1"],
            createdByMemberID: "m1"
        )
        try await repository.closePoll(created.poll)

        let active = try await repository.fetchActivePoll()

        XCTAssertNil(active)
    }
}
