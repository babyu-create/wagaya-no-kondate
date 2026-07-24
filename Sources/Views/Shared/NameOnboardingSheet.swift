import SwiftUI

struct NameOnboardingSheet: View {
    @EnvironmentObject private var environment: AppEnvironment

    @State private var name: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(AppTheme.accent)
                        Text("はじめまして！")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section("お名前") {
                    TextField("例: お母さん、たろう", text: $name)
                }

                Text("家族の評価や投票に表示される名前です。あとから設定タブで変更できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .warmScrollBackground()
            .navigationBarTitleDisplayMode(.inline)
            .errorAlert($errorMessage)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("はじめる") {
                        Task {
                            isSaving = true
                            let ok = await environment.memberDirectory.setDisplayName(
                                name.trimmingCharacters(in: .whitespaces),
                                memberID: environment.currentMemberID
                            )
                            isSaving = false
                            if !ok {
                                errorMessage = "保存できませんでした。通信環境を確認して、もう一度お試しください。"
                            }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}
