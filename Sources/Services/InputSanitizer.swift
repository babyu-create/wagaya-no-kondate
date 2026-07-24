import Foundation

/// ユーザー入力の軽い整形をまとめる。
enum InputSanitizer {
    /// 数字以外を取り除く（全角数字は半角に寄せてから抽出）。金額入力などに使う。
    static func digitsOnly(_ text: String) -> String {
        let halfwidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? text
        return halfwidth.filter { $0.isNumber && $0.isASCII }
    }
}

/// 参考URLの入力を正規化する。スキームが無ければ https:// を補い、開けるURLにする。
enum URLNormalizer {
    static func normalized(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://" + trimmed)
    }
}
