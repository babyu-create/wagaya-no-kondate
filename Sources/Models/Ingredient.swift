import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var displayName: String
    var amount: String

    /// 表記ゆれを吸収して比較用の名前を作る。
    /// カタカナ→ひらがな統一、全角英数字→半角、空白除去、大文字小文字を無視する。
    /// 例:「ジャガイモ」「じゃがいも」「 じゃがいも 」はすべて同じ扱いになる。
    static func normalize(_ name: String) -> String {
        var value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.applyingTransform(.hiraganaToKatakana, reverse: true) ?? value
        value = value.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? value
        value = value
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
        return value.lowercased()
    }

    var normalizedName: String {
        Ingredient.normalize(displayName)
    }
}
