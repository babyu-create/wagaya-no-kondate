import CloudKit
import SwiftUI

/// iCloudにサインインしていない、または利用できない場合に表示する案内画面。
/// これが無いと、CloudKitへのアクセスが全て失敗し続けてエラーだらけの画面になってしまう。
struct AccountIssueView: View {
    let status: CKAccountStatus

    private var message: String {
        switch status {
        case .noAccount:
            return "設定アプリの一番上からiCloudにサインインすると使えるようになります。"
        case .restricted:
            return "この端末ではiCloudの利用が制限されています。スクリーンタイムなどの設定をご確認ください。"
        case .temporarilyUnavailable:
            return "iCloudに一時的に接続できません。しばらくしてからもう一度開いてください。"
        default:
            return "iCloudの状態を確認できませんでした。通信環境をご確認のうえ、もう一度開いてください。"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            Text("iCloudへのサインインが必要です")
                .font(.title3.bold())
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}
