import XCTest
import CloudKit
@testable import WagayaNoKondate

final class RecipeMappingTests: XCTestCase {
    func testRoundTripPreservesFields() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let original = Recipe(
            id: "recipe-1",
            title: "肉じゃが",
            instructions: "1. 切る\n2. 煮る",
            sourceURL: URL(string: "https://example.com/recipe"),
            servings: 4,
            costPerServing: 150,
            genre: .japanese,
            ingredients: [
                Ingredient(displayName: "じゃがいも", amount: "3個"),
                Ingredient(displayName: "牛肉", amount: "200g")
            ],
            createdByMemberID: "member-1",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let record = original.toRecord(zoneID: zoneID)
        let restored = Recipe(record: record)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.title, original.title)
        XCTAssertEqual(restored?.instructions, original.instructions)
        XCTAssertEqual(restored?.sourceURL, original.sourceURL)
        XCTAssertEqual(restored?.servings, original.servings)
        XCTAssertEqual(restored?.costPerServing, original.costPerServing)
        XCTAssertEqual(restored?.genre, original.genre)
        XCTAssertEqual(restored?.ingredients, original.ingredients)
        XCTAssertEqual(restored?.createdByMemberID, original.createdByMemberID)
        XCTAssertEqual(restored?.createdAt, original.createdAt)
    }

    func testInitFailsForWrongRecordType() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "wrong", zoneID: zoneID)
        let record = CKRecord(recordType: "NotARecipe", recordID: recordID)

        XCTAssertNil(Recipe(record: record))
    }

    func testMissingRequiredFieldFailsGracefully() {
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: CKCurrentUserDefaultName)
        let recordID = CKRecord.ID(recordName: "incomplete", zoneID: zoneID)
        let record = CKRecord(recordType: Recipe.recordType, recordID: recordID)
        record["title"] = "タイトルだけ" as CKRecordValue

        XCTAssertNil(Recipe(record: record))
    }
}
