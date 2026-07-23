import SwiftUI

struct VotingView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        VotingContentView(
            pollRepository: environment.pollRepository,
            recipeRepository: environment.recipeRepository,
            reviewRepository: environment.reviewRepository,
            currentMemberID: environment.currentMemberID
        )
    }
}

private struct VotingContentView: View {
    @StateObject private var viewModel: VotingViewModel
    @State private var isPresentingCreatePoll = false

    init(
        pollRepository: PollRepository,
        recipeRepository: RecipeRepository,
        reviewRepository: ReviewRepository,
        currentMemberID: String
    ) {
        _viewModel = StateObject(
            wrappedValue: VotingViewModel(
                pollRepository: pollRepository,
                recipeRepository: recipeRepository,
                reviewRepository: reviewRepository,
                currentMemberID: currentMemberID
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.poll == nil {
                ProgressView()
            } else if let poll = viewModel.poll {
                activePollView(poll: poll)
            } else {
                ContentUnavailableView(
                    "今日の投票はまだありません",
                    systemImage: "checkmark.seal",
                    description: Text("右上の＋から投票を作成しましょう")
                )
            }
        }
        .navigationTitle("今日の投票")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingCreatePoll = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreatePoll) {
            NavigationStack {
                CreatePollView(viewModel: viewModel)
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

    private func activePollView(poll: Poll) -> some View {
        List {
            Section {
                ForEach(viewModel.results) { result in
                    if let recipe = viewModel.recipe(for: result.optionID) {
                        Button {
                            Task { await viewModel.castVote(optionID: result.optionID) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(recipe.title)
                                        .foregroundStyle(.primary)
                                    Text("\(result.count)票")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.myVote?.pollOptionID == result.optionID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                        .warmCardRow()
                    }
                }
            } header: {
                Text(pollTypeLabel(poll))
            }

            Section {
                Button(role: .destructive) {
                    Task { await viewModel.closeCurrentPoll() }
                } label: {
                    Text("投票を締め切る")
                }
                .warmCardRow()
            }
        }
        .listStyle(.plain)
        .warmScrollBackground()
    }

    private func pollTypeLabel(_ poll: Poll) -> String {
        switch poll.type {
        case .curated:
            return "候補から投票"
        case .topRated:
            return "評価4以上から投票"
        case .byGenre:
            return "\(poll.genre?.rawValue ?? "")料理から投票"
        }
    }
}
