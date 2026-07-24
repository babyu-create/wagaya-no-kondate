import SwiftUI

struct WeeklyView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        WeeklyContentView(
            recipeRepository: environment.recipeRepository,
            weeklyWishRepository: environment.weeklyWishRepository,
            currentMemberID: environment.currentMemberID
        )
    }
}

private struct WeeklyContentView: View {
    @StateObject private var viewModel: WeeklyViewModel

    init(
        recipeRepository: RecipeRepository,
        weeklyWishRepository: WeeklyWishRepository,
        currentMemberID: String
    ) {
        _viewModel = StateObject(
            wrappedValue: WeeklyViewModel(
                recipeRepository: recipeRepository,
                weeklyWishRepository: weeklyWishRepository,
                currentMemberID: currentMemberID
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.recipes.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "レシピがまだありません",
                    systemImage: "calendar",
                    description: Text("レシピタブから登録すると、ここでチェックできます")
                )
            } else {
                List {
                    if !viewModel.wishedRecipes.isEmpty {
                        Section("今週食べたい（\(viewModel.wishedRecipes.count)件）") {
                            ForEach(viewModel.wishedRecipes) { recipe in
                                weeklyRow(recipe)
                                    .warmCardRow()
                            }
                        }
                    }

                    if !viewModel.otherRecipes.isEmpty {
                        Section(viewModel.wishedRecipes.isEmpty ? "すべてのレシピ" : "ほかのレシピ") {
                            ForEach(viewModel.otherRecipes) { recipe in
                                weeklyRow(recipe)
                                    .warmCardRow()
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .warmScrollBackground()
            }
        }
        .navigationTitle("今週")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .errorAlert($viewModel.errorMessage)
    }

    private func weeklyRow(_ recipe: Recipe) -> some View {
        Button {
            Haptics.lightTap()
            Task { await viewModel.toggleWish(for: recipe) }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.title)
                        .foregroundStyle(.primary)
                    let count = viewModel.wishCount(for: recipe.id)
                    if count > 0 {
                        Text("\(count)人がリクエスト中")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: viewModel.isWishedByMe(recipe.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(viewModel.isWishedByMe(recipe.id) ? AppTheme.accent : Color.secondary)
            }
        }
    }
}
