import XCTest
import CloudKit
@testable import WagayaNoKondate

final class PollMappingTests: XCTestCase {
    private let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)

    func testPollRoundTripPreservesFields() {
        let original = Poll(
            id: "poll-1",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            type: .byGenre,
            genre: .japanese,
            status: .open,
            deadline: Date(timeIntervalSince1970: 1_700_003_600),
            createdByMemberID: "member-1"
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = Poll(record: record)

        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.date, original.date)
        XCTAssertEqual(restored?.type, original.type)
        XCTAssertEqual(restored?.genre, original.genre)
        XCTAssertEqual(restored?.status, original.status)
        XCTAssertEqual(restored?.deadline, original.deadline)
        XCTAssertEqual(restored?.createdByMemberID, original.createdByMemberID)
    }

    func testPollOptionRoundTrip() {
        let original = PollOption(id: "opt-1", pollID: "poll-1", recipeID: "recipe-1")

        let record = original.toRecord(zoneID: zoneID)
        let restored = PollOption(record: record)

        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.pollID, original.pollID)
        XCTAssertEqual(restored?.recipeID, original.recipeID)
    }

    func testVoteRoundTrip() {
        let original = Vote(
            id: Vote.upsertID(pollID: "poll-1", memberID: "member-1"),
            pollID: "poll-1",
            pollOptionID: "opt-1",
            memberID: "member-1",
            votedAt: Date(timeIntervalSince1970: 1_700_000_500)
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = Vote(record: record)

        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.pollID, original.pollID)
        XCTAssertEqual(restored?.pollOptionID, original.pollOptionID)
        XCTAssertEqual(restored?.memberID, original.memberID)
        XCTAssertEqual(restored?.votedAt, original.votedAt)
    }

    func testVoteUpsertIDIsDeterministic() {
        XCTAssertEqual(
            Vote.upsertID(pollID: "poll-1", memberID: "member-1"),
            Vote.upsertID(pollID: "poll-1", memberID: "member-1")
        )
    }
}
