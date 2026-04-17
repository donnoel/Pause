import SwiftUI

@main
struct PauseApp: App {
    private static let settingsVersionKey = "app_version_display"

    @StateObject private var appCoordinator = AppCoordinator()

    init() {
        PauseSessionStore.configureInsightsICloudSync()
        Self.updateSettingsVersionDisplay()
    }
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView()
        }
    }

    private static func updateSettingsVersionDisplay() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String

        guard let version, !version.isEmpty else { return }

        let displayValue: String
        if let build, !build.isEmpty {
            displayValue = "\(version) (\(build))"
        } else {
            displayValue = version
        }

        UserDefaults.standard.set(displayValue, forKey: settingsVersionKey)
    }
}
