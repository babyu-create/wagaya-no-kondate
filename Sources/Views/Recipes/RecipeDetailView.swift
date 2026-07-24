import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    /// 編集内容を呼び出し元（一覧）へ伝えるためのコールバック。
    var onRecipeChanged: (Recipe) -> Void = { _ in }
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        RecipeDetailContentView(
            recipe: recipe,
            reviewRepository: environment.reviewRepository,
            currentMemberID: environment.currentMemberID,
            memberDirectory: environment.memberDirectory,
            onRecipeChanged: onRecipeChanged
        )
    }
}

private struct RecipeDetailContentView: View {
    @StateObject private var viewModel: RecipeDetailViewModel
    @ObservedObject private var memberDirectory: MemberDirectory
    private let onRecipeChanged: (Recipe) -> Void
    @State private var isPresentingEditForm = false
    @State private var commentDraft = ""

    init(
        recipe: Recipe,
        reviewRepository: ReviewRepository,
        currentMemberID: String,
        memberDirectory: MemberDirectory,
        onRecipeChanged: @escaping (Recipe) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: RecipeDetailViewModel(
                recipe: recipe,
                reviewRepository: reviewRepository,
                currentMemberID: currentMemberID
            )
        )
        self.memberDirectory = memberDirectory
        self.onRecipeChanged = onRecipeChanged
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RecipeThumbnail(url: viewModel.recipe.localImageURL, cornerRadius: 12)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                Text(viewModel.recipe.title)
                    .font(.title2.bold())

                HStack(spacing: 12) {
                    Label(viewModel.recipe.genre.rawValue, systemImage: "tag")
                    Label("\(viewModel.recipe.servings)人前", systemImage: "person.2")
                    if let cost = viewModel.recipe.costPerServing {
                        Label("¥\(cost)/人前", systemImage: "yensign.circle")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let sourceURL = viewModel.recipe.sourceURL {
                    Link(destination: sourceURL) {
                        Label("参考ページを開く", systemImage: "link")
                    }
                }

                WarmCard { reviewSection }

                if !viewModel.recipe.ingredients.isEmpty {
                    WarmCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("材料")
                                .font(.headline)
                            ForEach(viewModel.recipe.ingredients) { ingredient in
                                HStack {
                                    Text(ingredient.displayName)
                                    Spacer()
                                    Text(ingredient.amount)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                WarmCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("作り方")
                            .font(.headline)
                        Text(viewModel.recipe.instructions)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(viewModel.recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") {
                    isPresentingEditForm = true
                }
            }
        }
        .sheet(isPresented: $isPresentingEditForm) {
            NavigationStack {
                RecipeFormView(existingRecipe: viewModel.recipe) { updated in
                    viewModel.applyEdit(updated)
                    onRecipeChanged(updated)
                }
            }
        }
        .task {
            await viewModel.load()
            commentDraft = viewModel.myComment
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("家族の評価")
                .font(.headline)

            if let average = viewModel.averageRating {
                HStack(spacing: 8) {
                    StarRatingView(rating: average)
                    Text(String(format: "%.1f（%d件）", average, viewModel.reviews.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("まだ評価がありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("あなたの評価")
                    .font(.subheadline)
                StarRatingPicker(
                    rating: Binding(
                        get: { viewModel.myRating },
                        set: { newValue in
                            Task { await viewModel.submitRating(newValue) }
                        }
                    )
                )

                if viewModel.myRating > 0 {
                    HStack {
                        TextField("ひとことコメント（任意）", text: $commentDraft)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                        if commentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            != viewModel.myComment.trimmingCharacters(in: .whitespacesAndNewlines) {
                            Button("保存") {
                                Task { await viewModel.submitComment(commentDraft) }
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 4)

            if !viewModel.otherReviews.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(viewModel.otherReviews) { review in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("\(memberDirectory.avatarEmoji(for: review.memberID) ?? "🙂") \(memberDirectory.displayName(for: review.memberID) ?? "家族の1人")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                StarRatingView(rating: Double(review.rating), size: 12)
                            }
                            if let comment = review.comment, !comment.isEmpty {
                                Text(comment)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}
