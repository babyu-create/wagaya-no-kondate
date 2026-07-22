import Foundation

@MainActor
final class RecipeDetailViewModel: ObservableObject {
    let recipe: Recipe

    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let reviewRepository: ReviewRepository
    private let currentMemberID: String

    init(recipe: Recipe, reviewRepository: ReviewRepository, currentMemberID: String) {
        self.recipe = recipe
        self.reviewRepository = reviewRepository
        self.currentMemberID = currentMemberID
    }

    var averageRating: Double? {
        ReviewAggregator.averageRating(for: recipe.id, reviews: reviews)
    }

    var myRating: Int {
        reviews.first { $0.memberID == currentMemberID }?.rating ?? 0
    }

    var otherReviews: [Review] {
        reviews.filter { $0.memberID != currentMemberID }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            reviews = try await reviewRepository.fetchAll(recipeID: recipe.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitRating(_ rating: Int) async {
        do {
            let saved = try await reviewRepository.upsert(
                recipeID: recipe.id,
                memberID: currentMemberID,
                rating: rating,
                comment: nil
            )
            if let index = reviews.firstIndex(where: { $0.id == saved.id }) {
                reviews[index] = saved
            } else {
                reviews.append(saved)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
