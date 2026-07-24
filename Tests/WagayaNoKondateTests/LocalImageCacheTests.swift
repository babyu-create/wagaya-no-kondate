import XCTest
import UIKit
@testable import WagayaNoKondate

final class LocalImageCacheTests: XCTestCase {
    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20))
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }

    private func makeFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("localimagecache-\(UUID().uuidString).jpg")
    }

    func testStoreThenCachedImageReturnsSameInstance() {
        let url = makeFileURL()
        let image = makeImage()

        LocalImageCache.store(image, for: url)

        XCTAssertTrue(LocalImageCache.cachedImage(for: url) === image)
        LocalImageCache.removeCachedImage(for: url)
    }

    func testCachedImageIsNilForUnknownURL() {
        let url = makeFileURL()
        XCTAssertNil(LocalImageCache.cachedImage(for: url))
    }

    func testRemoveCachedImageClearsEntry() {
        let url = makeFileURL()
        LocalImageCache.store(makeImage(), for: url)

        LocalImageCache.removeCachedImage(for: url)

        XCTAssertNil(LocalImageCache.cachedImage(for: url))
    }

    func testLoadImageReadsFromDiskAndPopulatesCache() async throws {
        let url = makeFileURL()
        let data = try XCTUnwrap(makeImage().jpegData(compressionQuality: 0.8))
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let loaded = await LocalImageCache.loadImage(for: url)

        XCTAssertNotNil(loaded)
        // 2回目はキャッシュから即座に返る。
        XCTAssertNotNil(LocalImageCache.cachedImage(for: url))
        LocalImageCache.removeCachedImage(for: url)
    }

    func testLoadImageReturnsNilForMissingFile() async {
        let url = makeFileURL()
        let loaded = await LocalImageCache.loadImage(for: url)
        XCTAssertNil(loaded)
    }
}
