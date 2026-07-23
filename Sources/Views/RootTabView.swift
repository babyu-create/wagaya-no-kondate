import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView {
            NavigationStack {
                RecipeListView(repository: environment.recipeRepository)
            }
            .tabItem {
                Label("レシピ", systemImage: "fork.knife")
            }

            NavigationStack {
                FridgeView()
            }
            .tabItem {
                Label("冷蔵庫", systemImage: "refrigerator")
            }

            NavigationStack {
                VotingView()
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
        .environmentObject(AppEnvironment())
}
