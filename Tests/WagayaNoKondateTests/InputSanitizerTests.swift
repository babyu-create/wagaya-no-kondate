import XCTest
@testable import WagayaNoKondate

final class InputSanitizerTests: XCTestCase {
    // MARK: - digitsOnly

    func testDigitsOnlyKeepsOnlyNumbers() {
        XCTAssertEqual(InputSanitizer.digitsOnly("300円"), "300")
        XCTAssertEqual(InputSanitizer.digitsOnly("¥1,200"), "1200")
        XCTAssertEqual(InputSanitizer.digitsOnly("abc"), "")
    }

    func testDigitsOnlyConvertsFullwidthDigits() {
        XCTAssertEqual(InputSanitizer.digitsOnly("３００"), "300")
    }

    func testDigitsOnlyEmptyStaysEmpty() {
        XCTAssertEqual(InputSanitizer.digitsOnly(""), "")
    }

    // MARK: - URLNormalizer

    func testNormalizedReturnsNilForBlank() {
        XCTAssertNil(URLNormalizer.normalized(from: "   "))
    }

    func testNormalizedKeepsExistingScheme() {
        let url = URLNormalizer.normalized(from: "https://cookpad.com/recipe/1")
        XCTAssertEqual(url?.absoluteString, "https://cookpad.com/recipe/1")
    }

    func testNormalizedPrependsHTTPSWhenSchemeMissing() {
        let url = URLNormalizer.normalized(from: "cookpad.com/recipe/1")
        XCTAssertEqual(url?.absoluteString, "https://cookpad.com/recipe/1")
    }

    func testNormalizedPreservesHTTPScheme() {
        let url = URLNormalizer.normalized(from: "http://example.com")
        XCTAssertEqual(url?.absoluteString, "http://example.com")
    }
}
