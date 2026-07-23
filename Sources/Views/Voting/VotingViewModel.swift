import Foundation

@MainActor
final class VotingViewModel: ObservableObject {
    @Published var poll: Poll?
    @Published var options: [PollOption] = []
    @Published var votes: [Vote] = []
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let pollRepository: PollRepository
    private let recipeRepository: RecipeRepository
    private let reviewRepository: ReviewRepository
    private let currentMemberID: String

    init(
        pollRepository: PollRepository,
        recipeRepository: RecipeRepository,
        reviewRepository: ReviewRepository,
        currentMemberID: String
    ) {
        self.pollRepository = pollRepository
        self.recipeRepository = recipeRepository
        self.reviewRepository = reviewRepository
        self.currentMemberID = currentMemberID
    }

    var results: [VoteTally.Result] {
        VoteTally.tally(options: options, votes: votes)
    }

    var myVote: Vote? {
        votes.first { $0.memberID == currentMemberID }
    }

    func recipe(for optionID: String) -> Recipe? {
        guard let option = options.first(where: { $0.id == optionID }) else { return nil }
        return recipes.first { $0.id == option.recipeID }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            recipes = try await recipeRepository.fetchAll()
            if let active = try await pollRepository.fetchActivePoll() {
                poll = active.poll
                options = active.options
                votes = try await pollRepository.fetchVotes(pollID: active.poll.id)
            } else {
                poll = nil
                options = []
                votes = []
            }
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func castVote(optionID: String) async {
        guard let poll else { return }
        do {
            let vote = try await pollRepository.vote(pollID: poll.id, pollOptionID: optionID, memberID: currentMemberID)
            if let index = votes.firstIndex(where: { $0.id == vote.id }) {
                votes[index] = vote
            } else {
                votes.append(vote)
            }
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func createPoll(type: PollType, genre: Genre?, recipeIDs: [String]) async {
        guard !recipeIDs.isEmpty else {
            errorMessage = "候補となるレシピがありません"
            return
        }
        do {
            let created = try await pollRepository.createPoll(
                type: type,
                genre: genre,
                deadline: nil,
                recipeIDs: recipeIDs,
                createdByMemberID: currentMemberID
            )
            poll = created.poll
            options = created.options
            votes = []
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func startTopRatedPoll(threshold: Int = 4) async {
        do {
            var allReviews: [Review] = []
            for recipe in recipes {
                allReviews.append(contentsOf: try await reviewRepository.fetchAll(recipeID: recipe.id))
            }
            let eligible = ReviewAggregator.recipes(ratedAtLeast: threshold, recipes: recipes, reviews: allReviews)
            await createPoll(type: .topRated, genre: nil, recipeIDs: eligible.map(\.id))
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }

    func startGenrePoll(genre: Genre) async {
        let matching = recipes.filter { $0.genre == genre }
        await createPoll(type: .byGenre, genre: genre, recipeIDs: matching.map(\.id))
    }

    func closeCurrentPoll() async {
        guard let poll else { return }
        do {
            try await pollRepository.closePoll(poll)
            self.poll = nil
            options = []
            votes = []
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }
}
