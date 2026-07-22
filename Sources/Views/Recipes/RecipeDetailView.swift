import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RecipeThumbnail(url: recipe.localImageURL, cornerRadius: 12)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                Text(recipe.title)
                    .font(.title2.bold())

                HStack(spacing: 12) {
                    Label(recipe.genre.rawValue, systemImage: "tag")
                    Label("\(recipe.servings)人前", systemImage: "person.2")
                    if let cost = recipe.costPerServing {
                        Label("¥\(cost)/人前", systemImage: "yensign.circle")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let sourceURL = recipe.sourceURL {
                    Link(destination: sourceURL) {
                        Label("参考ページを開く", systemImage: "link")
                    }
                }

                if !recipe.ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("材料")
                            .font(.headline)
                        ForEach(recipe.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.displayName)
                                Spacer()
                                Text(ingredient.amount)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("作り方")
                        .font(.headline)
                    Text(recipe.instructions)
                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
