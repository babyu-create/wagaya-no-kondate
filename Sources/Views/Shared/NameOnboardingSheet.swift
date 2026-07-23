import SwiftUI

struct NameOnboardingSheet: View {
    @EnvironmentObject private var environment: AppEnvironment

    @State private var name: String = ""
    @State private var isSaving = false

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
