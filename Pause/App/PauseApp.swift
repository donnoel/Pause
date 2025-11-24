import SwiftUI

@main
struct PauseApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView()
        }
    }
}
