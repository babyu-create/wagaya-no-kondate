import SwiftUI

extension View {
    /// エラーメッセージ用の共通アラート。
    /// `message` が非nilのとき表示し、閉じるとnilに戻す。
    /// 各画面に散らばっていた同じalertボイラープレートをここに集約している。
    func errorAlert(_ message: Binding<String?>) -> some View {
        alert(
            "エラー",
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("OK") { message.wrappedValue = nil }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
