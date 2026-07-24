import SwiftUI

/// アイコン用の絵文字を選ぶための簡易グリッド。家族メンバーのアバターに使う。
struct EmojiPickerSheet: View {
    let selected: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let choices = [
        "🙂", "😊", "😄", "🥰", "😎", "🤓",
        "👦", "👧", "👨", "👩", "👴", "👵",
        "🐶", "🐱", "🐰", "🐻", "🐼", "🦊",
        "🍙", "🍎", "🍕", "🍰", "☕️", "⭐️"
    ]

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Self.choices, id: \.self) { emoji in
                        Button {
                            onSelect(emoji)
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle().fill(emoji == selected ? AppTheme.accentSoft : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .warmScrollBackground()
            .navigationTitle("アイコンを選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
