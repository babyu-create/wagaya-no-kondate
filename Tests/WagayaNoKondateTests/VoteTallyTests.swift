import XCTest
@testable import WagayaNoKondate

final class VoteTallyTests: XCTestCase {
    func testTallyCountsVotesPerOptionDescending() {
        let options = [
            PollOption(id: "opt1", pollID: "poll1", recipeID: "r1"),
            PollOption(id: "opt2", pollID: "poll1", recipeID: "r2")
        ]
        let votes = [
            Vote(pollID: "poll1", pollOptionID: "opt1", memberID: "m1"),
            Vote(pollID: "poll1", pollOptionID: "opt1", memberID: "m2"),
            Vote(pollID: "poll1", pollOptionID: "opt2", memberID: "m3")
        ]

        let results = VoteTally.tally(options: options, votes: votes)

        XCTAssertEqual(results.first?.optionID, "opt1")
        XCTAssertEqual(results.first?.count, 2)
        XCTAssertEqual(results.last?.count, 1)
    }

    func testWinnerReturnsNilWhenNoOptions() {
        XCTAssertNil(VoteTally.winner(options: [], votes: []))
    }

    func testOptionsWithNoVotesHaveZeroCount() {
        let options = [PollOption(id: "opt1", pollID: "poll1", recipeID: "r1")]
        let results = VoteTally.tally(options: options, votes: [])
        XCTAssertEqual(results.first?.count, 0)
    }

    func testShareIsFractionOfTotal() {
        XCTAssertEqual(VoteTally.share(count: 3, total: 4), 0.75, accuracy: 0.0001)
    }

    func testShareIsZeroWhenTotalIsZero() {
        XCTAssertEqual(VoteTally.share(count: 0, total: 0), 0)
    }
}

final class PollDeadlineTests: XCTestCase {
    private func poll(deadline: Date?) -> Poll {
        Poll(type: .curated, deadline: deadline, createdByMemberID: "m1")
    }

    func testNotExpiredWhenNoDeadline() {
        XCTAssertFalse(PollDeadline.isExpired(poll(deadline: nil), now: Date()))
    }

    func testNotExpiredBeforeDeadline() {
        let now = Date(timeIntervalSince1970: 1_000)
        let future = Date(timeIntervalSince1970: 2_000)
        XCTAssertFalse(PollDeadline.isExpired(poll(deadline: future), now: now))
    }

    func testExpiredAtOrAfterDeadline() {
        let deadline = Date(timeIntervalSince1970: 1_000)
        let later = Date(timeIntervalSince1970: 1_001)
        XCTAssertTrue(PollDeadline.isExpired(poll(deadline: deadline), now: later))
        XCTAssertTrue(PollDeadline.isExpired(poll(deadline: deadline), now: deadline))
    }
}
