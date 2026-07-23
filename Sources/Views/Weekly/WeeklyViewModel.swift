import Foundation

@MainActor
final class WeeklyViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var wishes: [WeeklyWish] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let weekOf: String

    private let recipeRepository: RecipeRepository
    private let weeklyWishRepository: WeeklyWishRepository
    private let currentMemberID: String

    init(
        recipeRepository: RecipeRepository,
        weeklyWishRepository: WeeklyWishRepository,
        currentMemberID: String,
        weekOf: String = WeekIdentifier.current()
    ) {
        self.recipeRepository = recipeRepository
        self.weeklyWishRepository = weeklyWishRepository
        self.currentMemberID = currentMemberID
        self.weekOf = weekOf
    }

    var wishedRecipes: [Recipe] {
        recipes.filter { isWishedByMe($0.id) }
    }

    func wishCount(for recipeID: String) -> Int {
        wishes.filter { $0.recipeID == recipeID }.count
    }

    func isWishedByMe(_ recipeID: String) -> Bool {
        wishes.contains { $0.recipeID == recipeID && $0.memberID == currentMemberID }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let recipesTask = recipeRepository.fetchAll()
            async let wishesTask = weeklyWishRepository.fetchAll(weekOf: weekOf)
            recipes = try await recipesTask
            wishes = try await wishesTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleWish(for recipe: Recipe) async {
        do {
            let result = try await weeklyWishRepository.toggle(
                recipeID: recipe.id,
                memberID: currentMemberID,
                weekOf: weekOf
            )
            if let result {
                wishes.append(result)
            } else {
                wishes.removeAll { $0.recipeID == recipe.id && $0.memberID == currentMemberID }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
