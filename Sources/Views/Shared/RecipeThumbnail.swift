import SwiftUI
import UIKit

struct RecipeThumbnail: View {
    let url: URL?
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let url, let uiImage = UIImage.loadCached(from: url) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private extension UIImage {
    static func loadCached(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
