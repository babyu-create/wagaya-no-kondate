import Foundation

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            recipes = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        let targets = offsets.map { recipes[$0] }
        for recipe in targets {
            do {
                try await repository.delete(id: recipe.id)
                recipes.removeAll { $0.id == recipe.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func insert(_ recipe: Recipe) {
        recipes.insert(recipe, at: 0)
    }
}
