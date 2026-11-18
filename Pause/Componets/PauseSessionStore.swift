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
    static let completedSessionsDidChange = Notification.Name("PauseCompletedSessionsDidChange")
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
    #if DEBUG
    private static var testDefaults: UserDefaults?
    #endif

    private static var defaults: UserDefaults? {
        #if DEBUG
        if let testDefaults { return testDefaults }
        #endif
        return UserDefaults(suiteName: suiteName)
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
        // Unit tests must not erase device history or upload synthetic sessions to iCloud.
        if testDefaults == nil {
            testDefaults = UserDefaults(suiteName: "dn.Pause.tests.\(UUID().uuidString)")
        }
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

    @discardableResult
    static func recordCompletedSession(
        startDate: Date,
        endDate: Date,
        plannedDuration: TimeInterval
    ) -> CompletedMeditationSessionRecord? {
        guard plannedDuration > 0, endDate > startDate else { return nil }

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
        if mergedRecords != existingRecords {
            saveCompletedSessions(mergedRecords, syncToICloud: true)
            reloadWidgetTimelines()
        }
        return mergedRecords.first { CompletedSessionRecordMerger.isApproximatelyDuplicate($0, newRecord) }
    }

    @discardableResult
    static func saveReflection(_ reflection: SessionReflection, for session: CompletedMeditationSessionRecord) -> Bool {
        var records = loadCompletedSessions()
        guard let index = records.firstIndex(where: {
            CompletedSessionRecordMerger.isApproximatelyDuplicate($0, session)
        }) else { return false }

        records[index].reflection = reflection
        records[index].reflectionUpdatedAt = Date()
        saveCompletedSessions(records, syncToICloud: true)
        return true
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
        #if DEBUG
        if testDefaults != nil { return [] }
        #endif
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
        NotificationCenter.default.post(name: completedSessionsDidChange, object: nil)
    }

    private static func saveCompletedSessionsToICloud(_ records: [CompletedMeditationSessionRecord]) {
        #if DEBUG
        if testDefaults != nil { return }
        #endif
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
