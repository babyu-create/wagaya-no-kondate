import PhotosUI
import SwiftUI
import UIKit

struct RecipeFormView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var onSaved: (Recipe) -> Void

    @State private var title: String = ""
    @State private var instructions: String = ""
    @State private var sourceURLString: String = ""
    @State private var servings: Int = 2
    @State private var costPerServingText: String = ""
    @State private var genre: Genre = .japanese
    @State private var ingredients: [Ingredient] = []
    @State private var newIngredientName: String = ""
    @State private var newIngredientAmount: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        Form {
            Section("写真") {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("写真を選択", systemImage: "photo.badge.plus")
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        selectedImageData = try? await newItem?.loadTransferable(type: Data.self)
                    }
                }
            }

            Section("基本情報") {
                TextField("料理名", text: $title)
                TextField("参考URL", text: $sourceURLString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                Stepper("何人前: \(servings)", value: $servings, in: 1...10)
                TextField("1人前あたりの金額（円）", text: $costPerServingText)
                    .keyboardType(.numberPad)
                Picker("ジャンル", selection: $genre) {
                    ForEach(Genre.allCases) { genreOption in
                        Text(genreOption.rawValue).tag(genreOption)
                    }
                }
            }

            Section("材料") {
                ForEach(ingredients) { ingredient in
                    HStack {
                        Text(ingredient.displayName)
                        Spacer()
                        Text(ingredient.amount)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    ingredients.remove(atOffsets: offsets)
                }

                HStack {
                    TextField("材料名", text: $newIngredientName)
                    TextField("分量", text: $newIngredientAmount)
                        .frame(width: 80)
                    Button {
                        addIngredient()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("作り方") {
                TextEditor(text: $instructions)
                    .frame(minHeight: 120)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("レシピを追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task { await save() }
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
        }
    }

    private func addIngredient() {
        let name = newIngredientName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        ingredients.append(Ingredient(displayName: name, amount: newIngredientAmount))
        newIngredientName = ""
        newIngredientAmount = ""
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let recipe = Recipe(
            title: title.trimmingCharacters(in: .whitespaces),
            instructions: instructions,
            sourceURL: URL(string: sourceURLString),
            servings: servings,
            costPerServing: Int(costPerServingText),
            genre: genre,
            ingredients: ingredients,
            createdByMemberID: environment.currentMemberID,
            localImageURL: writeImageToTempFileIfNeeded()
        )

        do {
            let saved = try await environment.recipeRepository.save(recipe)
            onSaved(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func writeImageToTempFileIfNeeded() -> URL? {
        guard let selectedImageData else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try selectedImageData.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
