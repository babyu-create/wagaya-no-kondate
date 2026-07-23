import SwiftUI
import UIKit

/// 「わが家の献立」全体の見た目のトーン: 温かみ・手作り感。
/// クリーム色の背景 + テラコッタ系のアクセントで、家族の食卓の雰囲気を出す。
enum AppTheme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.11, blue: 0.10, alpha: 1)
            : UIColor(red: 0.98, green: 0.95, blue: 0.89, alpha: 1)
    })

    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.17, blue: 0.14, alpha: 1)
            : UIColor(red: 1.0, green: 0.99, blue: 0.96, alpha: 1)
    })

    static let accent = Color(red: 0.80, green: 0.42, blue: 0.24)
    static let accentSoft = Color(red: 0.95, green: 0.82, blue: 0.65)
    static let warmPlaceholder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.26, green: 0.22, blue: 0.18, alpha: 1)
            : UIColor(red: 0.93, green: 0.87, blue: 0.76, alpha: 1)
    })
    static let starGold = Color(red: 0.93, green: 0.66, blue: 0.20)
}

/// 温かみのある丸角カードで内容を包む共通コンテナ。
struct WarmCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardBackground)
            )
    }
}

extension View {
    /// リストの行を、丸角・浮いたカードのように見せる。区切り線は隠す。
    func warmCardRow() -> some View {
        listRowBackground(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
                .padding(.vertical, 4)
        )
        .listRowSeparator(.hidden)
    }

    /// List/Formの背景をクリーム色に差し替える共通処理。
    func warmScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(AppTheme.background)
    }
}
