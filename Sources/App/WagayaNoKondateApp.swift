import SwiftUI

@main
struct WagayaNoKondateApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            Group {
                if environment.isBootstrapped {
                    RootTabView()
                } else {
                    ProgressView("準備しています…")
                }
            }
            .environmentObject(environment)
            .task {
                await environment.bootstrap()
            }
        }
    }
}
