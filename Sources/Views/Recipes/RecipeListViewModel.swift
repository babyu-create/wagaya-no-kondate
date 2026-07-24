import Foundation

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: RecipeRepository
    private let reviewRepository: ReviewRepository
    private let weeklyWishRepository: WeeklyWishRepository

    init(repository: RecipeRepository, reviewRepository: ReviewRepository, weeklyWishRepository: WeeklyWishRepository) {
        self.repository = repository
        self.reviewRepository = reviewRepository
        self.weeklyWishRepository = weeklyWishRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            recipes = try await repository.fetchAll()
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func delete(at offsets: IndexSet) async {
        let targets = offsets.map { recipes[$0] }
        for recipe in targets {
            do {
                try await repository.delete(id: recipe.id)
                async let deleteReviews: () = reviewRepository.deleteAll(recipeID: recipe.id)
                async let deleteWishes: () = weeklyWishRepository.deleteAll(recipeID: recipe.id)
                _ = try await (deleteReviews, deleteWishes)
                // レシピ本体・関連データを消したら、残った写真ファイルも取り除く。
                ImageStore.delete(recipeID: recipe.id)
                recipes.removeAll { $0.id == recipe.id }
            } catch {
                errorMessage = AppError.message(for: error)
            }
        }
    }

    func insert(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
    }

    /// 詳細画面で編集されたレシピを一覧にも反映する。
    /// これがないと、編集して一覧に戻ったとき古いタイトル・写真のままになる。
    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe
    }
}
