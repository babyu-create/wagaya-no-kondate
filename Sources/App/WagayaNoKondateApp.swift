import SwiftUI

@main
struct WagayaNoKondateApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(environment)
                .task {
                    await environment.resolveCurrentMemberID()
                }
        }
    }
}
