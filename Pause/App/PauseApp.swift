import SwiftUI

@main
struct PauseApp: App {
    @StateObject private var appCoordinator = AppCoordinator()

    init() {
        PauseSessionStore.configureInsightsICloudSync()
    }
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView()
        }
    }
}
