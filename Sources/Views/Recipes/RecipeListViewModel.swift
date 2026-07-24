import Foundation

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published private(set) var averageRatings: [String: Double] = [:]
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

    func averageRating(for recipeID: String) -> Double? {
        averageRatings[recipeID]
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let recipesTask = repository.fetchAll()
            async let reviewsTask = reviewRepository.fetchAllReviews()
            recipes = try await recipesTask
            averageRatings = Self.computeAverages(recipes: recipes, reviews: try await reviewsTask)
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    /// 各レシピの平均評価をまとめて算出する。
    static func computeAverages(recipes: [Recipe], reviews: [Review]) -> [String: Double] {
        var result: [String: Double] = [:]
        for recipe in recipes {
            if let average = ReviewAggregator.averageRating(for: recipe.id, reviews: reviews) {
                result[recipe.id] = average
            }
        }
        return result
    }

    func delete(at offsets: IndexSet) async {
        await delete(offsets.map { recipes[$0] })
    }

    /// 指定したレシピ群を削除する。検索で絞り込んだ一覧からでも、
    /// インデックスではなくレシピ自体を渡すことで正しい対象を消せる。
    func delete(_ targets: [Recipe]) async {
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
