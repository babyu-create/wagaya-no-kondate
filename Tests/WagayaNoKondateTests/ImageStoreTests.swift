import XCTest
import UIKit
@testable import WagayaNoKondate

final class ImageStoreTests: XCTestCase {
    private func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testResizedShrinksImageLargerThanMaxDimension() {
        let large = makeImage(width: 3000, height: 2000)

        let resized = ImageStore.resized(large, maxDimension: 1200)

        XCTAssertEqual(resized.size.width, 1200, accuracy: 0.5)
        XCTAssertEqual(resized.size.height, 800, accuracy: 0.5)
    }

    func testResizedLeavesSmallImageUnchanged() {
        let small = makeImage(width: 400, height: 300)

        let resized = ImageStore.resized(small, maxDimension: 1200)

        XCTAssertEqual(resized.size.width, 400, accuracy: 0.5)
        XCTAssertEqual(resized.size.height, 300, accuracy: 0.5)
    }

    func testSaveWritesJPEGFileAndReturnsURL() throws {
        let image = makeImage(width: 800, height: 600)
        guard let data = image.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        let url = ImageStore.save(imageData: data, recipeID: "test-recipe-\(UUID().uuidString)")

        let unwrappedURL = try XCTUnwrap(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: unwrappedURL.path))
        XCTAssertEqual(unwrappedURL.pathExtension, "jpg")

        try? FileManager.default.removeItem(at: unwrappedURL)
    }

    func testSaveOverwritesFileForSameRecipeID() throws {
        let recipeID = "overwrite-test-\(UUID().uuidString)"
        let first = makeImage(width: 800, height: 600)
        let second = makeImage(width: 400, height: 300)

        guard let firstData = first.pngData(), let secondData = second.pngData() else {
            XCTFail("Failed to create test image data")
            return
        }

        let firstURL = try XCTUnwrap(ImageStore.save(imageData: firstData, recipeID: recipeID))
        let secondURL = try XCTUnwrap(ImageStore.save(imageData: secondData, recipeID: recipeID))

        XCTAssertEqual(firstURL, secondURL)

        try? FileManager.default.removeItem(at: secondURL)
    }

    func testDeleteRemovesSavedImageFile() throws {
        let recipeID = "delete-test-\(UUID().uuidString)"
        let image = makeImage(width: 400, height: 300)
        let data = try XCTUnwrap(image.pngData())

        let url = try XCTUnwrap(ImageStore.save(imageData: data, recipeID: recipeID))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        ImageStore.delete(recipeID: recipeID)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeleteForNonexistentImageDoesNotThrow() {
        // ファイルが無くても例外を投げず、静かに何もしない。
        ImageStore.delete(recipeID: "never-saved-\(UUID().uuidString)")
    }
}
