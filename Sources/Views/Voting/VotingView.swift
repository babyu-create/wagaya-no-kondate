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
        .errorAlert($viewModel.errorMessage)
    }

    private func activePollView(poll: Poll) -> some View {
        List {
            if let deadline = poll.deadline {
                Section {
                    Label(deadlineLabel(deadline), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .warmCardRow()
                }
            }

            Section {
                ForEach(viewModel.results) { result in
                    if let recipe = viewModel.recipe(for: result.optionID) {
                        Button {
                            Haptics.lightTap()
                            Task { await viewModel.castVote(optionID: result.optionID) }
                        } label: {
                            voteRow(recipe: recipe, result: result)
                        }
                        .disabled(viewModel.isVotingClosed)
                        .warmCardRow()
                    }
                }
            } header: {
                Text(pollTypeLabel(poll))
            } footer: {
                if viewModel.isVotingClosed {
                    Text("この投票は締め切られました。")
                        .foregroundStyle(AppTheme.accent)
                }
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

    private func voteRow(recipe: Recipe, result: VoteTally.Result) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recipe.title)
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.myVote?.pollOptionID == result.optionID {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }
                Text("\(result.count)票")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: VoteTally.share(count: result.count, total: viewModel.totalVotes))
                .tint(AppTheme.accent)
        }
    }

    private func deadlineLabel(_ deadline: Date) -> String {
        if deadline < Date() {
            return "締め切りを過ぎています（\(deadline.formatted(date: .abbreviated, time: .shortened))）"
        }
        return "締め切り: \(deadline.formatted(date: .abbreviated, time: .shortened))"
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
