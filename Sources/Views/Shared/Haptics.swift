import UIKit

/// 主要な操作に触覚フィードバックを添えるための薄いラッパー。
/// 実機では反応が返り、シミュレータでは自動的に無視される。
enum Haptics {
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
