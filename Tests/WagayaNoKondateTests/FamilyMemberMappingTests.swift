import XCTest
import CloudKit
@testable import WagayaNoKondate

final class FamilyMemberMappingTests: XCTestCase {
    func testRoundTripPreservesFields() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let original = FamilyMember(
            id: "member-1",
            displayName: "お母さん",
            avatarEmoji: "👩",
            iCloudUserRecordName: "icloud-user-1"
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = FamilyMember(record: record)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.displayName, original.displayName)
        XCTAssertEqual(restored?.avatarEmoji, original.avatarEmoji)
        XCTAssertEqual(restored?.iCloudUserRecordName, original.iCloudUserRecordName)
    }

    func testInitFailsForWrongRecordType() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "wrong", zoneID: zoneID)
        let record = CKRecord(recordType: "NotAMember", recordID: recordID)

        XCTAssertNil(FamilyMember(record: record))
    }
}
