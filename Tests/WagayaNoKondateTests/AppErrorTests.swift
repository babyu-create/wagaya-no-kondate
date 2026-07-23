import XCTest
import CloudKit
@testable import WagayaNoKondate

final class AppErrorTests: XCTestCase {
    func testNetworkUnavailableMapsToFriendlyMessage() {
        let error = CKError(.networkUnavailable)
        XCTAssertEqual(AppError.message(for: error), "通信環境を確認してから、もう一度お試しください。")
    }

    func testNotAuthenticatedMentionsSignIn() {
        let error = CKError(.notAuthenticated)
        XCTAssertTrue(AppError.message(for: error).contains("サインイン"))
    }

    func testZoneNotFoundMentionsInvite() {
        let error = CKError(.zoneNotFound)
        XCTAssertTrue(AppError.message(for: error).contains("招待"))
    }

    func testNonCKErrorFallsBackToGenericMessage() {
        struct SomeError: Error {}
        XCTAssertEqual(AppError.message(for: SomeError()), "エラーが発生しました。もう一度お試しください。")
    }
}
