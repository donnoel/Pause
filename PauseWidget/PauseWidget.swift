import WidgetKit
import SwiftUI

// MARK: - Entry

struct PauseLockScreenEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let endDate: Date?
}

// MARK: - Shared session store for widget

private struct PauseSessionInfo: Codable {
    var isActive: Bool
    var endDate: Date?
}

private enum PauseSessionStore {
    // Must match the App Group ID configured in both app and widget targets
    private static let suiteName = "group.dn.pause"
    private static let key = "currentSession"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
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
}

// MARK: - Timeline Provider

struct PauseLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> PauseLockScreenEntry {
        PauseLockScreenEntry(
            date: Date(),
            isActive: true,
            endDate: Date().addingTimeInterval(10 * 60)
        )
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (PauseLockScreenEntry) -> Void) {
        let info = PauseSessionStore.load()
        completion(
            PauseLockScreenEntry(
                date: Date(),
                isActive: info.isActive,
                endDate: info.endDate
            )
        )
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<PauseLockScreenEntry>) -> Void) {
        let info = PauseSessionStore.load()
        let now = Date()

        let entry = PauseLockScreenEntry(
            date: now,
            isActive: info.isActive,
            endDate: info.endDate
        )

        let policy: TimelineReloadPolicy
        if let end = info.endDate, info.isActive {
            policy = .after(end)
        } else {
            policy = .never
        }

        completion(Timeline(entries: [entry], policy: policy))
    }
}

// MARK: - View

struct PauseLockScreenWidgetView: View {
    var entry: PauseLockScreenEntry

    var body: some View {
        ZStack(alignment: .center) {
            // Circular ring to visually match other accessory circular widgets
            Circle()
                .strokeBorder(Color.primary.opacity(0.45), lineWidth: 4)

            if entry.isActive, let end = entry.endDate {
                // Compact timer for circular widget
                Text(timerInterval: entry.date...end, countsDown: true)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Text("Stillness")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Widget

struct PauseLockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "PauseLockScreenWidget",
            provider: PauseLockScreenProvider()
        ) { entry in
            PauseLockScreenWidgetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Pause Timer")
        .description("Shows your meditation countdown on the Lock Screen.")
        .supportedFamilies([.accessoryCircular])
    }
}
