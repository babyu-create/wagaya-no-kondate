import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel: RecipeListViewModel
    @State private var isPresentingForm = false

    init(repository: RecipeRepository) {
        _viewModel = StateObject(wrappedValue: RecipeListViewModel(repository: repository))
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
                List {
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeRow(recipe: recipe)
                        }
                        .warmCardRow()
                    }
                    .onDelete { offsets in
                        Task { await viewModel.delete(at: offsets) }
                    }
                }
                .listStyle(.plain)
                .warmScrollBackground()
            }
        }
        .background(AppTheme.background)
        .navigationTitle("レシピ")
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingForm = true
                } label: {
                    Image(systemName: "plus")
                }
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
}
