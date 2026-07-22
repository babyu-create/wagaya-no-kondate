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
}
