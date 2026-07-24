import SwiftUI
import UIKit

/// レシピ写真を全画面で表示し、ピンチで拡大できるビューア。
struct FullScreenImageView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = max(1, $0) }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3)) {
                                    scale = min(max(1, scale), 4)
                                }
                            }
                    )
                    .accessibilityLabel("レシピの写真")
            } else {
                ProgressView().tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding()
                    }
                    .accessibilityLabel("閉じる")
                }
                Spacer()
            }
        }
        .task {
            image = await LocalImageCache.loadImage(for: url)
        }
    }
}
