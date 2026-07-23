import CloudKit
import Foundation

/// CloudKitのエラーを、家族が読んで分かる日本語メッセージに変換する。
enum AppError {
    static func message(for error: Error) -> String {
        if let ckError = error as? CKError {
            return message(for: ckError)
        }
        return "エラーが発生しました。もう一度お試しください。"
    }

    private static func message(for error: CKError) -> String {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return "通信環境を確認してから、もう一度お試しください。"
        case .notAuthenticated:
            return "iCloudにサインインしていません。設定アプリからサインインしてください。"
        case .quotaExceeded:
            return "iCloudの空き容量が不足しています。"
        case .zoneNotFound, .userDeletedZone:
            return "家族の共有データが見つかりませんでした。設定タブから家族を招待し直してください。"
        case .permissionFailure:
            return "この操作を行う権限がありません。"
        case .serverRecordChanged:
            return "他の家族が同時に更新したようです。もう一度お試しください。"
        case .requestRateLimited, .zoneBusy, .serviceUnavailable:
            return "サーバーが混み合っています。しばらくしてからもう一度お試しください。"
        case .limitExceeded:
            return "一度に処理できる量を超えています。件数を減らしてお試しください。"
        default:
            return "エラーが発生しました。もう一度お試しください。"
        }
    }
}
