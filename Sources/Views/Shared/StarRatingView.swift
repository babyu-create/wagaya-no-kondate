import SwiftUI

struct StarRatingView: View {
    var rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 16
    var color: Color = AppTheme.starGold

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: symbolName(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(maxRating)段階中 \(String(format: "%.1f", rating))")
    }

    private func symbolName(for index: Int) -> String {
        let value = rating - Double(index - 1)
        if value >= 1 {
            return "star.fill"
        } else if value >= 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct StarRatingPicker: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var size: CGFloat = 28
    var color: Color = AppTheme.starGold

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxRating, id: \.self) { index in
                Button {
                    rating = index
                    Haptics.lightTap()
                } label: {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundStyle(color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(index)つ星")
                .accessibilityAddTraits(index == rating ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("評価")
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 3.5)
        StarRatingPicker(rating: .constant(4))
    }
}
