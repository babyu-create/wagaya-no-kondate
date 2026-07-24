import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel: RecipeListViewModel
    @State private var isPresentingForm = false
    @State private var searchText = ""
    @State private var pendingDeleteTargets: [Recipe] = []
    @State private var isConfirmingDelete = false

    init(repository: RecipeRepository, reviewRepository: ReviewRepository, weeklyWishRepository: WeeklyWishRepository) {
        _viewModel = StateObject(
            wrappedValue: RecipeListViewModel(
                repository: repository,
                reviewRepository: reviewRepository,
                weeklyWishRepository: weeklyWishRepository
            )
        )
    }

    private var filteredRecipes: [Recipe] {
        RecipeSearch.filter(viewModel.recipes, query: searchText)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.recipes.isEmpty {
                ProgressView()
            } else if viewModel.recipes.isEmpty {
                ContentUnavailableView(
                    "レシピがまだありません",
                    systemImage: "fork.knife",
                    description: Text("右上の＋から最初のレシピを登録しましょう")
                )
            } else {
                recipeList
            }
        }
        .background(AppTheme.background)
        .navigationTitle("レシピ")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe) { updated in
                viewModel.update(updated)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("レシピを追加")
            }
        }
        .sheet(isPresented: $isPresentingForm) {
            NavigationStack {
                RecipeFormView { saved in
                    viewModel.insert(saved)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .confirmationDialog(
            "このレシピを削除しますか？",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                let targets = pendingDeleteTargets
                pendingDeleteTargets = []
                Task { await viewModel.delete(targets) }
            }
            Button("キャンセル", role: .cancel) {
                pendingDeleteTargets = []
            }
        } message: {
            Text("評価・今週食べたいのデータも一緒に削除されます。この操作は取り消せません。")
        }
        .errorAlert($viewModel.errorMessage)
    }

    private var recipeList: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRow(recipe: recipe)
                }
                .warmCardRow()
            }
            .onDelete { offsets in
                pendingDeleteTargets = offsets.map { filteredRecipes[$0] }
                isConfirmingDelete = true
            }
        }
        .listStyle(.plain)
        .warmScrollBackground()
        .searchable(text: $searchText, prompt: "レシピ・材料・ジャンルで検索")
        .overlay {
            if !searchText.isEmpty && filteredRecipes.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}
