import XCTest
@testable import WagayaNoKondate

@MainActor
final class VotingViewModelTests: XCTestCase {
    private func makeViewModel(
        pollRepository: PollRepository = InMemoryPollRepository(),
        recipeRepository: RecipeRepository = InMemoryRecipeRepository(),
        reviewRepository: ReviewRepository = InMemoryReviewRepository(),
        currentMemberID: String = "m1"
    ) -> VotingViewModel {
        VotingViewModel(
            pollRepository: pollRepository,
            recipeRepository: recipeRepository,
            reviewRepository: reviewRepository,
            currentMemberID: currentMemberID
        )
    }

    func testLoadWithNoActivePollLeavesPollNil() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        XCTAssertNil(viewModel.poll)
    }

    func testCreatePollThenLoadShowsPollAndOptions() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let pollRepository = InMemoryPollRepository()
        let recipe = try await recipeRepository.save(
            Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )

        let viewModel = makeViewModel(pollRepository: pollRepository, recipeRepository: recipeRepository)
        await viewModel.load()
        await viewModel.createPoll(type: .curated, genre: nil, recipeIDs: [recipe.id])

        XCTAssertNotNil(viewModel.poll)
        XCTAssertEqual(viewModel.options.count, 1)
    }

    func testCreatePollWithDeadlinePropagatesToPoll() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let recipe = try await recipeRepository.save(
            Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        let deadline = Date().addingTimeInterval(3600)

        let viewModel = makeViewModel(recipeRepository: recipeRepository)
        await viewModel.load()
        await viewModel.createPoll(type: .curated, genre: nil, recipeIDs: [recipe.id], deadline: deadline)

        XCTAssertEqual(viewModel.poll?.deadline, deadline)
    }

    func testCreatePollWithNoRecipesSetsErrorMessage() async {
        let viewModel = makeViewModel()
        await viewModel.createPoll(type: .curated, genre: nil, recipeIDs: [])
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.poll)
    }

    func testCastVoteUpdatesMyVoteAndResults() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let recipe = try await recipeRepository.save(
            Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        let viewModel = makeViewModel(recipeRepository: recipeRepository, currentMemberID: "m1")
        await viewModel.load()
        await viewModel.createPoll(type: .curated, genre: nil, recipeIDs: [recipe.id])

        let optionID = try XCTUnwrap(viewModel.options.first?.id)
        await viewModel.castVote(optionID: optionID)

        XCTAssertEqual(viewModel.myVote?.pollOptionID, optionID)
        XCTAssertEqual(viewModel.results.first?.count, 1)
    }

    func testCloseCurrentPollClearsPollAndVotes() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let recipe = try await recipeRepository.save(
            Recipe(title: "カレー", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        let viewModel = makeViewModel(recipeRepository: recipeRepository)
        await viewModel.load()
        await viewModel.createPoll(type: .curated, genre: nil, recipeIDs: [recipe.id])

        await viewModel.closeCurrentPoll()

        XCTAssertNil(viewModel.poll)
        XCTAssertTrue(viewModel.options.isEmpty)
    }

    func testStartTopRatedPollOnlyIncludesRecipesMeetingThreshold() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let reviewRepository = InMemoryReviewRepository()
        let highRated = try await recipeRepository.save(
            Recipe(title: "高評価", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        let lowRated = try await recipeRepository.save(
            Recipe(title: "低評価", instructions: "-", servings: 2, genre: .other, createdByMemberID: "m1")
        )
        _ = try await reviewRepository.upsert(recipeID: highRated.id, memberID: "m1", rating: 5, comment: nil)
        _ = try await reviewRepository.upsert(recipeID: lowRated.id, memberID: "m1", rating: 2, comment: nil)

        let viewModel = makeViewModel(recipeRepository: recipeRepository, reviewRepository: reviewRepository)
        await viewModel.load()
        await viewModel.startTopRatedPoll(threshold: 4)

        let includedRecipeIDs = viewModel.options.map(\.recipeID)
        XCTAssertTrue(includedRecipeIDs.contains(highRated.id))
        XCTAssertFalse(includedRecipeIDs.contains(lowRated.id))
    }

    func testStartGenrePollOnlyIncludesMatchingGenre() async throws {
        let recipeRepository = InMemoryRecipeRepository()
        let japanese = try await recipeRepository.save(
            Recipe(title: "味噌汁", instructions: "-", servings: 2, genre: .japanese, createdByMemberID: "m1")
        )
        let western = try await recipeRepository.save(
            Recipe(title: "パスタ", instructions: "-", servings: 2, genre: .western, createdByMemberID: "m1")
        )

        let viewModel = makeViewModel(recipeRepository: recipeRepository)
        await viewModel.load()
        await viewModel.startGenrePoll(genre: .japanese)

        let includedRecipeIDs = viewModel.options.map(\.recipeID)
        XCTAssertTrue(includedRecipeIDs.contains(japanese.id))
        XCTAssertFalse(includedRecipeIDs.contains(western.id))
    }
}
