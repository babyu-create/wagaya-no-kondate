import UIKit

/// レシピ写真をリサイズ・圧縮して永続領域(Application Support)に保存する。
/// tmpディレクトリはOSに任意のタイミングで消される可能性があるため使わない。
enum ImageStore {
    private static let directoryName = "RecipePhotos"
    private static let maxDimension: CGFloat = 1200
    private static let compressionQuality: CGFloat = 0.7

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// recipeIDに対応する保存先URL（存在有無を問わない）。
    static func imageURL(for recipeID: String) -> URL {
        directory.appendingPathComponent("\(recipeID).jpg")
    }

    /// レシピ削除時に、対応する画像ファイルを永続領域から取り除く。
    /// これを呼ばないと削除済みレシピの写真がディスクに残り続ける。
    static func delete(recipeID: String) {
        let url = imageURL(for: recipeID)
        try? FileManager.default.removeItem(at: url)
    }

    /// 画像データをリサイズ・JPEG圧縮して保存し、保存先のURLを返す。
    /// 同じrecipeIDで再保存すると上書きされ、編集のたびにファイルが増え続けることはない。
    static func save(imageData: Data, recipeID: String) -> URL? {
        guard let image = UIImage(data: imageData) else { return nil }
        let resized = resized(image, maxDimension: maxDimension)
        guard let jpegData = resized.jpegData(compressionQuality: compressionQuality) else { return nil }

        let url = imageURL(for: recipeID)
        do {
            try jpegData.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension, longestSide > 0 else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
