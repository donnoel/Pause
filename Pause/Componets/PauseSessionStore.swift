import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct PauseSessionInfo: Codable {
    var isActive: Bool
    var startDate: Date?
    var endDate: Date?
}

enum PauseSessionStore {
    // IMPORTANT: This must match the App Group ID used by the widget target
    private static let suiteName = "group.dn.pause"
    private static let key = "currentSession"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func save(_ info: PauseSessionInfo) {
        guard let defaults else { return }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(info) {
            defaults.set(data, forKey: key)
        }
        reloadWidgetTimelines()
    }

    static func load() -> PauseSessionInfo {
        guard
            let defaults,
            let data = defaults.data(forKey: key),
            let info = try? JSONDecoder().decode(PauseSessionInfo.self, from: data)
        else {
            return PauseSessionInfo(isActive: false, endDate: nil)
        }

        return info
    }

    static func clear() {
        guard let defaults else { return }
        defaults.removeObject(forKey: key)
        reloadWidgetTimelines()
    }
    
    private static func reloadWidgetTimelines() {
        #if canImport(WidgetKit)
        if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "PauseLockScreenWidget")
        } else {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
}
