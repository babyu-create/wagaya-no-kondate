import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        RootTabContentView(environment: environment)
    }
}

private struct RootTabContentView: View {
    @ObservedObject private var environment: AppEnvironment
    @ObservedObject private var memberDirectory: MemberDirectory

    init(environment: AppEnvironment) {
        self.environment = environment
        self.memberDirectory = environment.memberDirectory
    }

    var body: some View {
        TabView {
            NavigationStack {
                RecipeListView(
                    repository: environment.recipeRepository,
                    reviewRepository: environment.reviewRepository,
                    weeklyWishRepository: environment.weeklyWishRepository
                )
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
                WeeklyView()
            }
            .tabItem {
                Label("今週", systemImage: "calendar")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
        .tint(AppTheme.accent)
        .fontDesign(.rounded)
        .sheet(
            isPresented: Binding(
                get: { memberDirectory.displayName(for: environment.currentMemberID) == nil },
                set: { _ in }
            )
        ) {
            NameOnboardingSheet()
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppEnvironment())
}
