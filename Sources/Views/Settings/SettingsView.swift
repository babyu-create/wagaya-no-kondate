import CloudKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    @State private var share: CKShare?
    @State private var isSharing = false
    @State private var isPreparingShare = false
    @State private var errorMessage: String?

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
                    }
                }
                .disabled(isPreparingShare)

                Text("招待リンクを送ると、家族のiPhoneでレシピや投票がすべて共有されます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("このデバイスの情報") {
                LabeledContent("メンバーID", value: String(environment.currentMemberID.prefix(8)))
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("設定")
        .sheet(isPresented: $isSharing) {
            if let share {
                CloudSharingView(share: share, container: environment.cloudKitService.container)
            }
        }
    }

    private func prepareAndPresentShare() async {
        isPreparingShare = true
        defer { isPreparingShare = false }
        do {
            try await environment.cloudKitService.ensureFamilyZoneExists()
            share = try await environment.cloudKitService.fetchOrCreateFamilyShare()
            isSharing = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
