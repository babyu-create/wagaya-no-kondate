import SwiftUI

struct NameOnboardingSheet: View {
    @EnvironmentObject private var environment: AppEnvironment

    @State private var name: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("お名前") {
                    TextField("例: お母さん、たろう", text: $name)
                }

                Text("家族の評価や投票に表示される名前です。あとから設定タブで変更できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("はじめまして！")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("はじめる") {
                        Task {
                            isSaving = true
                            await environment.memberDirectory.setDisplayName(
                                name.trimmingCharacters(in: .whitespaces),
                                memberID: environment.currentMemberID
                            )
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}
