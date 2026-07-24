import Foundation

@MainActor
final class FridgeViewModel: ObservableObject {
    @Published var fridgeItems: [FridgeItem] = []
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fridgeRepository: FridgeItemRepository
    private let recipeRepository: RecipeRepository
    private let currentMemberID: String

    init(fridgeRepository: FridgeItemRepository, recipeRepository: RecipeRepository, currentMemberID: String) {
        self.fridgeRepository = fridgeRepository
        self.recipeRepository = recipeRepository
        self.currentMemberID = currentMemberID
    }

    private var matches: [FridgeMatcher.MatchResult] {
        FridgeMatcher.match(recipes: recipes, fridgeItems: fridgeItems)
    }

    var makeableRecipes: [FridgeMatcher.MatchResult] {
        matches.filter { $0.isFullyAvailable }
    }

    var almostMakeableRecipes: [FridgeMatcher.MatchResult] {
        matches.filter { !$0.isFullyAvailable && $0.missingIngredients.count <= 2 }
    }

    /// レシピに登場する材料名から重複を除いたもの。材料入力のサジェストに使う。
    var knownIngredientNames: [String] {
        KnownIngredients.names(from: recipes)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let itemsTask = fridgeRepository.fetchAll()
            async let recipesTask = recipeRepository.fetchAll()
            fridgeItems = try await itemsTask
            recipes = try await recipesTask
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func addItem(name: String, quantity: String?) async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        do {
            let saved = try await fridgeRepository.save(
                FridgeItem(displayName: trimmedName, quantity: quantity, updatedByMemberID: currentMemberID)
            )
            fridgeItems.insert(saved, at: 0)
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func delete(at offsets: IndexSet) async {
        let targets = offsets.map { fridgeItems[$0] }
        for item in targets {
            do {
                try await fridgeRepository.delete(id: item.id)
                fridgeItems.removeAll { $0.id == item.id }
            } catch {
                errorMessage = AppError.message(for: error)
            }
        }
    }
}
