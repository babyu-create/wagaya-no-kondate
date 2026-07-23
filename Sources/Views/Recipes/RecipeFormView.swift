import PhotosUI
import SwiftUI
import UIKit

struct RecipeFormView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    private let existingRecipe: Recipe?
    var onSaved: (Recipe) -> Void

    @State private var title: String
    @State private var instructions: String
    @State private var sourceURLString: String
    @State private var servings: Int
    @State private var costPerServingText: String
    @State private var genre: Genre
    @State private var ingredients: [Ingredient]
    @State private var newIngredientName: String = ""
    @State private var newIngredientAmount: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var existingImageURL: URL?

    init(existingRecipe: Recipe? = nil, onSaved: @escaping (Recipe) -> Void) {
        self.existingRecipe = existingRecipe
        self.onSaved = onSaved
        _title = State(initialValue: existingRecipe?.title ?? "")
        _instructions = State(initialValue: existingRecipe?.instructions ?? "")
        _sourceURLString = State(initialValue: existingRecipe?.sourceURL?.absoluteString ?? "")
        _servings = State(initialValue: existingRecipe?.servings ?? 2)
        _costPerServingText = State(initialValue: existingRecipe?.costPerServing.map(String.init) ?? "")
        _genre = State(initialValue: existingRecipe?.genre ?? .japanese)
        _ingredients = State(initialValue: existingRecipe?.ingredients ?? [])
        _existingImageURL = State(initialValue: existingRecipe?.localImageURL)
    }

    private var isEditing: Bool { existingRecipe != nil }

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
                    } else if let existingImageURL {
                        RecipeThumbnail(url: existingImageURL, cornerRadius: 8)
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
        .warmScrollBackground()
        .navigationTitle(isEditing ? "レシピを編集" : "レシピを追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "更新" : "保存") {
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

        let imageURL: URL?
        if selectedImageData != nil {
            imageURL = writeImageToTempFileIfNeeded()
        } else {
            imageURL = existingImageURL
        }

        let recipe = Recipe(
            id: existingRecipe?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespaces),
            instructions: instructions,
            sourceURL: URL(string: sourceURLString),
            servings: servings,
            costPerServing: Int(costPerServingText),
            genre: genre,
            ingredients: ingredients,
            createdByMemberID: existingRecipe?.createdByMemberID ?? environment.currentMemberID,
            createdAt: existingRecipe?.createdAt ?? Date(),
            localImageURL: imageURL
        )

        do {
            let saved = try await environment.recipeRepository.save(recipe)
            onSaved(saved)
            dismiss()
        } catch {
            errorMessage = AppError.message(for: error)
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
