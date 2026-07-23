import XCTest
import CloudKit
@testable import WagayaNoKondate

final class WeeklyWishMappingTests: XCTestCase {
    func testRoundTripPreservesFields() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let original = WeeklyWish(
            id: WeeklyWish.upsertID(recipeID: "r1", memberID: "m1", weekOf: "2026-W30"),
            recipeID: "r1",
            memberID: "m1",
            weekOf: "2026-W30"
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = WeeklyWish(record: record)

        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.recipeID, original.recipeID)
        XCTAssertEqual(restored?.memberID, original.memberID)
        XCTAssertEqual(restored?.weekOf, original.weekOf)
    }

    func testUpsertIDIsDeterministicPerRecipeMemberAndWeek() {
        let idA = WeeklyWish.upsertID(recipeID: "r1", memberID: "m1", weekOf: "2026-W30")
        let idB = WeeklyWish.upsertID(recipeID: "r1", memberID: "m1", weekOf: "2026-W30")
        let idC = WeeklyWish.upsertID(recipeID: "r1", memberID: "m1", weekOf: "2026-W31")

        XCTAssertEqual(idA, idB)
        XCTAssertNotEqual(idA, idC)
    }
}
