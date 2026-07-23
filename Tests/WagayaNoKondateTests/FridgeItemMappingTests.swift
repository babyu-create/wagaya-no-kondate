import XCTest
import CloudKit
@testable import WagayaNoKondate

final class FridgeItemMappingTests: XCTestCase {
    func testRoundTripPreservesFields() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let original = FridgeItem(
            id: "fridge-1",
            displayName: "じゃがいも",
            quantity: "3個",
            updatedByMemberID: "member-1",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = FridgeItem(record: record)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.displayName, original.displayName)
        XCTAssertEqual(restored?.quantity, original.quantity)
        XCTAssertEqual(restored?.updatedByMemberID, original.updatedByMemberID)
        XCTAssertEqual(restored?.updatedAt, original.updatedAt)
    }

    func testInitFailsForWrongRecordType() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "wrong", zoneID: zoneID)
        let record = CKRecord(recordType: "NotAFridgeItem", recordID: recordID)

        XCTAssertNil(FridgeItem(record: record))
    }
}
