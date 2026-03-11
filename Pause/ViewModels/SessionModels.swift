import Foundation

/// High-level state of the current meditation session.
enum SessionState {
    case idle
    case running
    case paused
    case completed
}

/// Fixed duration presets, expressed in seconds via `TimeInterval` raw values.
enum SessionDurationPreset: TimeInterval, CaseIterable, Identifiable {
    case five = 300
    case ten = 600
    case fifteen = 900
    case twenty = 1200

    var id: TimeInterval { rawValue }

    /// Duration in whole minutes for this preset.
    var minutes: Int {
        Int(rawValue / 60)
    }

    /// Human-friendly label used in the UI.
    var label: String {
        "\(minutes) min"
    }
}

/// Persisted record for a fully completed meditation session.
struct CompletedMeditationSessionRecord: Codable, Equatable {
    let startDate: Date
    let endDate: Date
    let plannedDuration: TimeInterval
}

/// Aggregated stats used by the UI.
struct SessionStatsSummary: Equatable {
    let completedDateComponents: Set<DateComponents>
    let lastCompletedSession: CompletedMeditationSessionRecord?
    let usualMeditationMinutesFromMidnight: Int?
    let averageSessionLength: TimeInterval?
    let completedSessionCount: Int

    static let empty = SessionStatsSummary(
        completedDateComponents: [],
        lastCompletedSession: nil,
        usualMeditationMinutesFromMidnight: nil,
        averageSessionLength: nil,
        completedSessionCount: 0
    )
}

enum SessionStatsCalculator {
    static func makeSummary(
        from records: [CompletedMeditationSessionRecord],
        calendar: Calendar = .current
    ) -> SessionStatsSummary {
        guard !records.isEmpty else { return .empty }

        let completedDateComponents = Set(
            records.map {
                calendar.dateComponents([.year, .month, .day], from: $0.endDate)
            }
        )

        let lastCompletedSession = records.max(by: { $0.endDate < $1.endDate })

        let startMinutes = records.compactMap { record -> Int? in
            let components = calendar.dateComponents([.hour, .minute], from: record.startDate)
            guard let hour = components.hour, let minute = components.minute else { return nil }
            return (hour * 60) + minute
        }

        let usualMeditationMinutes: Int?
        if startMinutes.isEmpty {
            usualMeditationMinutes = nil
        } else {
            let averageStartMinutes = Double(startMinutes.reduce(0, +)) / Double(startMinutes.count)
            usualMeditationMinutes = Int(averageStartMinutes.rounded())
        }

        let validDurations = records
            .map(\.plannedDuration)
            .filter { $0 > 0 }

        let averageSessionLength: TimeInterval?
        if validDurations.isEmpty {
            averageSessionLength = nil
        } else {
            averageSessionLength = validDurations.reduce(0, +) / Double(validDurations.count)
        }

        return SessionStatsSummary(
            completedDateComponents: completedDateComponents,
            lastCompletedSession: lastCompletedSession,
            usualMeditationMinutesFromMidnight: usualMeditationMinutes,
            averageSessionLength: averageSessionLength,
            completedSessionCount: records.count
        )
    }
}
