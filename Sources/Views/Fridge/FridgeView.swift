import SwiftUI

struct FridgeView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        FridgeContentView(
            fridgeRepository: environment.fridgeItemRepository,
            recipeRepository: environment.recipeRepository,
            currentMemberID: environment.currentMemberID
        )
    }
}

private struct FridgeContentView: View {
    @StateObject private var viewModel: FridgeViewModel
    @State private var newItemName = ""
    @State private var newItemQuantity = ""

    init(fridgeRepository: FridgeItemRepository, recipeRepository: RecipeRepository, currentMemberID: String) {
        _viewModel = StateObject(
            wrappedValue: FridgeViewModel(
                fridgeRepository: fridgeRepository,
                recipeRepository: recipeRepository,
                currentMemberID: currentMemberID
            )
        )
    }

    var body: some View {
        List {
            Section("追加") {
                HStack {
                    TextField("材料名", text: $newItemName)
                    TextField("数量（任意）", text: $newItemQuantity)
                        .frame(width: 100)
                    Button {
                        Task {
                            await viewModel.addItem(
                                name: newItemName,
                                quantity: newItemQuantity.isEmpty ? nil : newItemQuantity
                            )
                            newItemName = ""
                            newItemQuantity = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if !viewModel.makeableRecipes.isEmpty {
                Section("今すぐ作れるレシピ") {
                    ForEach(viewModel.makeableRecipes) { match in
                        Label(match.recipe.title, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            if !viewModel.almostMakeableRecipes.isEmpty {
                Section("あと少しで作れるレシピ") {
                    ForEach(viewModel.almostMakeableRecipes) { match in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(match.recipe.title)
                            Text("あと: " + match.missingIngredients.map(\.displayName).joined(separator: "、"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("冷蔵庫にあるもの") {
                if viewModel.fridgeItems.isEmpty {
                    Text("まだ何も登録されていません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.fridgeItems) { item in
                        HStack {
                            Text(item.displayName)
                            if let quantity = item.quantity, !quantity.isEmpty {
                                Spacer()
                                Text(quantity)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        Task { await viewModel.delete(at: offsets) }
                    }
                }
            }
        }
        .navigationTitle("冷蔵庫")
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
}
