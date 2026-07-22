import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("レシピ")
                    .navigationTitle("レシピ")
            }
            .tabItem {
                Label("レシピ", systemImage: "fork.knife")
            }

            NavigationStack {
                Text("冷蔵庫")
                    .navigationTitle("冷蔵庫")
            }
            .tabItem {
                Label("冷蔵庫", systemImage: "refrigerator")
            }

            NavigationStack {
                Text("今日の投票")
                    .navigationTitle("今日の投票")
            }
            .tabItem {
                Label("投票", systemImage: "checkmark.seal")
            }

            NavigationStack {
                Text("今週")
                    .navigationTitle("今週")
            }
            .tabItem {
                Label("今週", systemImage: "calendar")
            }

            NavigationStack {
                Text("設定")
                    .navigationTitle("設定")
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    RootTabView()
}
