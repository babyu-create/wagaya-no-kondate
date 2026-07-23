import SwiftUI

@main
struct WagayaNoKondateApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            Group {
                if environment.isBootstrapped {
                    if environment.accountStatus == .available {
                        RootTabView()
                    } else {
                        AccountIssueView(status: environment.accountStatus)
                    }
                } else {
                    ZStack {
                        AppTheme.background.ignoresSafeArea()
                        ProgressView("準備しています…")
                            .tint(AppTheme.accent)
                    }
                }
            }
            .environmentObject(environment)
            .fontDesign(.rounded)
            .task {
                await environment.bootstrap()
            }
        }
    }
}
