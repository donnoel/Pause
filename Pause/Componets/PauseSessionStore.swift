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
    private static let completedSessionsKey = "completedSessions"
    private static let maxCompletedSessionCount = 3650
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func save(_ info: PauseSessionInfo) {
        guard let defaults else { return }
        if let data = try? encoder.encode(info) {
            defaults.set(data, forKey: key)
        }
        reloadWidgetTimelines()
    }

    static func load() -> PauseSessionInfo {
        guard
            let defaults,
            let data = defaults.data(forKey: key),
            let info = try? decoder.decode(PauseSessionInfo.self, from: data)
        else {
            return PauseSessionInfo(isActive: false, startDate: nil, endDate: nil)
        }

        return info
    }

    static func clear() {
        guard let defaults else { return }
        defaults.removeObject(forKey: key)
        reloadWidgetTimelines()
    }

    static func loadCompletedSessions() -> [CompletedMeditationSessionRecord] {
        guard
            let defaults,
            let data = defaults.data(forKey: completedSessionsKey),
            let records = try? decoder.decode([CompletedMeditationSessionRecord].self, from: data)
        else {
            return []
        }

        return records.sorted { $0.endDate < $1.endDate }
    }

    static func recordCompletedSession(
        startDate: Date,
        endDate: Date,
        plannedDuration: TimeInterval
    ) {
        guard plannedDuration > 0, endDate > startDate else { return }

        let newRecord = CompletedMeditationSessionRecord(
            startDate: startDate,
            endDate: endDate,
            plannedDuration: plannedDuration
        )

        var records = loadCompletedSessions()
        let isDuplicate = records.contains {
            abs($0.startDate.timeIntervalSince(newRecord.startDate)) < 1 &&
            abs($0.endDate.timeIntervalSince(newRecord.endDate)) < 1 &&
            abs($0.plannedDuration - newRecord.plannedDuration) < 0.5
        }
        guard !isDuplicate else { return }

        records.append(newRecord)
        records.sort { $0.endDate < $1.endDate }

        if records.count > maxCompletedSessionCount {
            let overflow = records.count - maxCompletedSessionCount
            records.removeFirst(overflow)
        }

        guard
            let defaults,
            let data = try? encoder.encode(records)
        else {
            return
        }

        defaults.set(data, forKey: completedSessionsKey)
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
