import XCTest
import CloudKit
@testable import WagayaNoKondate

final class ReviewMappingTests: XCTestCase {
    func testRoundTripPreservesFields() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let original = Review(
            id: Review.upsertID(recipeID: "recipe-1", memberID: "member-1"),
            recipeID: "recipe-1",
            memberID: "member-1",
            rating: 4,
            comment: "また作りたい",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = Review(record: record)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.recipeID, original.recipeID)
        XCTAssertEqual(restored?.memberID, original.memberID)
        XCTAssertEqual(restored?.rating, original.rating)
        XCTAssertEqual(restored?.comment, original.comment)
        XCTAssertEqual(restored?.updatedAt, original.updatedAt)
    }

    func testUpsertIDIsDeterministicPerRecipeAndMember() {
        let idA = Review.upsertID(recipeID: "recipe-1", memberID: "member-1")
        let idB = Review.upsertID(recipeID: "recipe-1", memberID: "member-1")
        let idC = Review.upsertID(recipeID: "recipe-1", memberID: "member-2")

        XCTAssertEqual(idA, idB)
        XCTAssertNotEqual(idA, idC)
    }
}
