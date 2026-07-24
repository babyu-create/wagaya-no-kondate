import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe
    var averageRating: Double?

    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(url: recipe.localImageURL)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(recipe.genre.rawValue, systemImage: "tag.fill")
                        .foregroundStyle(AppTheme.accent)
                    if let cost = recipe.costPerServing {
                        Text("¥\(cost)/人前")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)

                if let averageRating {
                    HStack(spacing: 4) {
                        StarRatingView(rating: averageRating, size: 11)
                        Text(String(format: "%.1f", averageRating))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
