import WidgetKit
import SwiftUI

// MARK: - Entry

struct PauseLockScreenEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let endDate: Date?

    var isReady: Bool { !isActive }
}

// MARK: - Shared session store for widget

private struct PauseSessionInfo: Codable {
    var isActive: Bool
    var startDate: Date?
    var endDate: Date?
}

private enum PauseSessionStore {
    // Must match the App Group ID configured in both app and widget targets
    private static let suiteName = "group.dn.pause"
    private static let key = "currentSession"
    private static let decoder = JSONDecoder()

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
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
}

// MARK: - Timeline Provider

struct PauseLockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> PauseLockScreenEntry {
        PauseLockScreenEntry(
            date: Date(),
            isActive: true,
            endDate: Date().addingTimeInterval(5 * 60)
        )
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (PauseLockScreenEntry) -> Void) {
        let info = PauseSessionStore.load()
        let now = Date()

        let isActive: Bool
        let endDate: Date?

        if let end = info.endDate, info.isActive, end > now {
            isActive = true
            endDate = end
        } else {
            isActive = false
            endDate = nil
        }

        completion(
            PauseLockScreenEntry(
                date: now,
                isActive: isActive,
                endDate: endDate
            )
        )
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<PauseLockScreenEntry>) -> Void) {
        let info = PauseSessionStore.load()
        let now = Date()

        let isActive: Bool
        let endDate: Date?
        let policy: TimelineReloadPolicy

        if let end = info.endDate, info.isActive, end > now {
            // Active session that has not yet ended
            isActive = true
            endDate = end
            policy = .after(end)
        } else {
            // Session finished or not running – show a ready state.
            isActive = false
            endDate = nil
            policy = .never
        }

        let entry = PauseLockScreenEntry(
            date: now,
            isActive: isActive,
            endDate: endDate
        )

        completion(Timeline(entries: [entry], policy: policy))
    }
}

// MARK: - View

struct PauseLockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var entry: PauseLockScreenEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    private var circularView: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.35), lineWidth: 3)

            if entry.isActive, let end = entry.endDate {
                Text(timerInterval: entry.date...end, countsDown: true)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Ready")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
            }
        }
        .widgetAccentable()
    }

    private var rectangularView: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.16))
                Image(systemName: entry.isActive ? "timer" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.9))
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.isActive ? "Session in progress" : "Ready to begin")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .lineLimit(1)

                if entry.isActive, let end = entry.endDate {
                    Text(timerInterval: entry.date...end, countsDown: true)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("Tap to open Pause")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var inlineView: some View {
        Group {
            if entry.isActive, let end = entry.endDate {
                Text(timerInterval: entry.date...end, countsDown: true)
            } else {
                Text("Pause • Ready")
            }
        }
        .font(.system(.caption, design: .rounded).weight(.semibold))
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
        .configurationDisplayName("Pause")
        .description("Quickly check remaining time or jump back in when ready.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
