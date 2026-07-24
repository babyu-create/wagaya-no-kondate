import CloudKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        SettingsContentView(environment: environment)
    }
}

private struct SettingsContentView: View {
    @ObservedObject private var environment: AppEnvironment
    @ObservedObject private var memberDirectory: MemberDirectory

    @State private var share: CKShare?
    @State private var isSharing = false
    @State private var isPreparingShare = false
    @State private var errorMessage: String?
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var isPickingEmoji = false

    init(environment: AppEnvironment) {
        self.environment = environment
        self.memberDirectory = environment.memberDirectory
    }

    private var myDisplayName: String {
        memberDirectory.displayName(for: environment.currentMemberID) ?? "未設定"
    }

    private var myAvatarEmoji: String {
        memberDirectory.avatarEmoji(for: environment.currentMemberID) ?? "🙂"
    }

    var body: some View {
        List {
            Section("家族共有") {
                Button {
                    Task { await prepareAndPresentShare() }
                } label: {
                    if isPreparingShare {
                        ProgressView()
                    } else {
                        Label("家族を招待する", systemImage: "person.badge.plus")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .disabled(isPreparingShare)
                .warmCardRow()

                Text("招待リンクを送ると、家族のiPhoneでレシピや投票がすべて共有されます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .warmCardRow()
            }

            Section("このデバイスの情報") {
                Button {
                    editedName = memberDirectory.displayName(for: environment.currentMemberID) ?? ""
                    isEditingName = true
                } label: {
                    LabeledContent("あなたの表示名", value: myDisplayName)
                }
                .foregroundStyle(.primary)
                .warmCardRow()
                Button {
                    isPickingEmoji = true
                } label: {
                    LabeledContent("あなたのアイコン") {
                        Text(myAvatarEmoji).font(.title3)
                    }
                }
                .foregroundStyle(.primary)
                .warmCardRow()
                LabeledContent("メンバーID", value: String(environment.currentMemberID.prefix(8)))
                    .warmCardRow()
            }

            if memberDirectory.allMembers.count > 1 {
                Section("家族のメンバー") {
                    ForEach(memberDirectory.allMembers) { member in
                        HStack {
                            Text(member.avatarEmoji).font(.title3)
                            Text(member.displayName)
                            if member.id == environment.currentMemberID {
                                Spacer()
                                Text("あなた")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .warmCardRow()
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.plain)
        .warmScrollBackground()
        .navigationTitle("設定")
        .sheet(isPresented: $isSharing) {
            if let share, let cloudKitService = environment.cloudKitService {
                CloudSharingView(share: share, container: cloudKitService.container)
            }
        }
        .sheet(isPresented: $isPickingEmoji) {
            EmojiPickerSheet(selected: myAvatarEmoji) { emoji in
                Task {
                    await memberDirectory.setAvatarEmoji(emoji, memberID: environment.currentMemberID)
                }
            }
        }
        .alert("表示名を変更", isPresented: $isEditingName) {
            TextField("お名前", text: $editedName)
            Button("キャンセル", role: .cancel) {}
            Button("保存") {
                Task {
                    await memberDirectory.setDisplayName(
                        editedName.trimmingCharacters(in: .whitespaces),
                        memberID: environment.currentMemberID
                    )
                }
            }
        }
    }

    private func prepareAndPresentShare() async {
        guard let cloudKitService = environment.cloudKitService else {
            errorMessage = "iCloud機能を利用できません"
            return
        }
        isPreparingShare = true
        defer { isPreparingShare = false }
        do {
            try await cloudKitService.ensureFamilyZoneExists()
            share = try await cloudKitService.fetchOrCreateFamilyShare()
            isSharing = true
        } catch {
            errorMessage = AppError.message(for: error)
        }
    }
}
