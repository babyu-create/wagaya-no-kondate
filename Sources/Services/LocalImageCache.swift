import UIKit

/// ファイルURLの画像をメモリキャッシュしつつ、ディスク読込をバックグラウンドで行う。
///
/// これまで `RecipeThumbnail` は `body` 評価中にメインスレッドで `Data(contentsOf:)` を
/// 呼んでいたため、レシピが増えるほどリストのスクロールがカクついていた。
/// 一度読み込んだ画像はメモリに保持して即座に返し、未読込のものだけ
/// バックグラウンドで読み込むことで描画を滑らかにする。
enum LocalImageCache {
    // NSCache はスレッドセーフなので、複数の非同期タスクから同時に触れても安全。
    private static let cache = NSCache<NSURL, UIImage>()

    /// メモリキャッシュにあれば即座に返す（ディスクアクセスなし）。
    static func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    /// キャッシュを無視してディスクから読み込む用途（テスト等）に呼び分けたい場合に使う。
    static func removeCachedImage(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }

    /// バックグラウンドでディスクから画像を読み込み、デコードしてキャッシュに載せて返す。
    /// キャッシュ済みなら即座にそれを返す。
    static func loadImage(for url: URL) async -> UIImage? {
        if let cached = cachedImage(for: url) {
            return cached
        }
        let image = await Task.detached(priority: .utility) { () -> UIImage? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }.value
        if let image {
            store(image, for: url)
        }
        return image
    }
}
