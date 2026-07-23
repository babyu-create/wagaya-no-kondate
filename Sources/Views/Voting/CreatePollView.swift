import SwiftUI

struct CreatePollView: View {
    @ObservedObject var viewModel: VotingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: PollType = .curated
    @State private var selectedRecipeIDs: Set<String> = []
    @State private var selectedGenre: Genre = .japanese

    var body: some View {
        Form {
            Section("投票のタイプ") {
                Picker("タイプ", selection: $selectedType) {
                    Text("候補から選ぶ").tag(PollType.curated)
                    Text("評価4以上から自動").tag(PollType.topRated)
                    Text("ジャンル別").tag(PollType.byGenre)
                }
                .pickerStyle(.segmented)
            }

            switch selectedType {
            case .curated:
                Section("候補レシピを選択") {
                    if viewModel.recipes.isEmpty {
                        Text("レシピがまだ登録されていません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.recipes) { recipe in
                            Button {
                                toggle(recipe.id)
                            } label: {
                                HStack {
                                    Text(recipe.title)
                                    Spacer()
                                    if selectedRecipeIDs.contains(recipe.id) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            case .topRated:
                Section {
                    Text("家族評価が★4以上のレシピから自動で候補を作成します")
                        .foregroundStyle(.secondary)
                }
            case .byGenre:
                Section("ジャンル") {
                    Picker("ジャンル", selection: $selectedGenre) {
                        ForEach(Genre.allCases) { genre in
                            Text(genre.rawValue).tag(genre)
                        }
                    }
                }
            }
        }
        .warmScrollBackground()
        .navigationTitle("投票を作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("作成") {
                    Task {
                        await create()
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedRecipeIDs.contains(id) {
            selectedRecipeIDs.remove(id)
        } else {
            selectedRecipeIDs.insert(id)
        }
    }

    private func create() async {
        switch selectedType {
        case .curated:
            await viewModel.createPoll(type: .curated, genre: nil, recipeIDs: Array(selectedRecipeIDs))
        case .topRated:
            await viewModel.startTopRatedPoll()
        case .byGenre:
            await viewModel.startGenrePoll(genre: selectedGenre)
        }
    }
}
