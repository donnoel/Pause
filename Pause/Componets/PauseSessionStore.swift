import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct PauseSessionInfo: Codable {
    var isActive: Bool
    var startDate: Date?
    var endDate: Date?
    var plannedDuration: TimeInterval?
}

enum PauseSessionStore {
    // IMPORTANT: This must match the App Group ID used by the widget target
    private static let suiteName = "group.dn.pause"
    private static let key = "currentSession"
    private static let completedSessionsKey = "completedSessions"
    private static let cloudCompletedSessionsKey = "completedSessions"
    private static let maxCompletedSessionCount = 3650
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    private static let ubiquitousStore = NSUbiquitousKeyValueStore.default
    private static var iCloudSyncConfigured = false
    private static var iCloudObserver: NSObjectProtocol?

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

    #if DEBUG
    static func clearCompletedSessionsForTesting() {
        guard let defaults else { return }
        defaults.removeObject(forKey: completedSessionsKey)
        reloadWidgetTimelines()
    }
    #endif

    static func configureInsightsICloudSync() {
        guard !iCloudSyncConfigured else { return }
        iCloudSyncConfigured = true

        iCloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: ubiquitousStore,
            queue: nil
        ) { _ in
            mergeCompletedSessionsFromICloud()
        }

        ubiquitousStore.synchronize()
        mergeCompletedSessionsFromICloud()
    }

    static func loadCompletedSessions() -> [CompletedMeditationSessionRecord] {
        guard
            let defaults,
            let data = defaults.data(forKey: completedSessionsKey),
            let records = try? decoder.decode([CompletedMeditationSessionRecord].self, from: data)
        else {
            return []
        }

        return CompletedSessionRecordMerger.normalized(
            records,
            maxCount: maxCompletedSessionCount
        )
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

        let existingRecords = loadCompletedSessions()
        let mergedRecords = CompletedSessionRecordMerger.normalized(
            existingRecords + [newRecord],
            maxCount: maxCompletedSessionCount
        )
        guard mergedRecords != existingRecords else { return }

        saveCompletedSessions(mergedRecords, syncToICloud: true)
        reloadWidgetTimelines()
    }

    private static func mergeCompletedSessionsFromICloud() {
        let localRecords = loadCompletedSessions()
        let cloudRecords = loadCompletedSessionsFromICloud()
        let mergedRecords = CompletedSessionRecordMerger.normalized(
            localRecords + cloudRecords,
            maxCount: maxCompletedSessionCount
        )

        guard mergedRecords != localRecords || mergedRecords != cloudRecords else { return }

        saveCompletedSessions(mergedRecords, syncToICloud: false)
        saveCompletedSessionsToICloud(mergedRecords)
        reloadWidgetTimelines()
    }

    private static func loadCompletedSessionsFromICloud() -> [CompletedMeditationSessionRecord] {
        guard
            let cloudData = ubiquitousStore.data(forKey: cloudCompletedSessionsKey),
            let records = try? decoder.decode([CompletedMeditationSessionRecord].self, from: cloudData)
        else {
            return []
        }

        return CompletedSessionRecordMerger.normalized(
            records,
            maxCount: maxCompletedSessionCount
        )
    }

    private static func saveCompletedSessions(
        _ records: [CompletedMeditationSessionRecord],
        syncToICloud: Bool
    ) {
        guard
            let defaults,
            let data = try? encoder.encode(records)
        else {
            return
        }

        defaults.set(data, forKey: completedSessionsKey)

        if syncToICloud {
            saveCompletedSessionsToICloud(records)
        }
    }

    private static func saveCompletedSessionsToICloud(_ records: [CompletedMeditationSessionRecord]) {
        guard let data = try? encoder.encode(records) else { return }
        ubiquitousStore.set(data, forKey: cloudCompletedSessionsKey)
        ubiquitousStore.synchronize()
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
