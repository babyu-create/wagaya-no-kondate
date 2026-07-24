import SwiftUI
import UIKit

struct RecipeThumbnail: View {
    let url: URL?
    var cornerRadius: CGFloat = 8

    @State private var loadedImage: UIImage?

    /// キャッシュ済みなら同期で即座に取り出し（NSCache参照のみでディスクI/Oなし）、
    /// 画像切り替え時のプレースホルダのちらつきを防ぐ。
    private var displayImage: UIImage? {
        if let loadedImage { return loadedImage }
        if let url { return LocalImageCache.cachedImage(for: url) }
        return nil
    }

    var body: some View {
        Group {
            if let displayImage {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("レシピの写真")
            } else {
                ZStack {
                    AppTheme.warmPlaceholder
                    Image(systemName: "fork.knife")
                        .foregroundStyle(AppTheme.accent)
                }
                .accessibilityLabel("写真なし")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: url) {
            // キャッシュ済み・URLなしは何もしない。未読込のみバックグラウンドで読み込む。
            guard let url, LocalImageCache.cachedImage(for: url) == nil else { return }
            loadedImage = await LocalImageCache.loadImage(for: url)
        }
    }
}
