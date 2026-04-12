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

/// Breathing style selected before a session starts.
enum BreathingStyle: String, CaseIterable, Identifiable {
    case quietTimer
    case boxBreath
    case calmExhale
    case equalBreath

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quietTimer:
            return "Quiet Timer"
        case .boxBreath:
            return "Box Breath"
        case .calmExhale:
            return "Calm Exhale"
        case .equalBreath:
            return "Equal Breath"
        }
    }

    /// Lightweight phase cue model. Timing can be refined later.
    func phaseCue(elapsed: TimeInterval) -> String? {
        let elapsedSecond = max(0, Int(elapsed.rounded(.down)))

        switch self {
        case .quietTimer:
            return nil
        case .boxBreath:
            switch elapsedSecond % 16 {
            case 0...3:
                return "Inhale"
            case 4...7:
                return "Hold"
            case 8...11:
                return "Exhale"
            default:
                return "Hold"
            }
        case .calmExhale:
            switch elapsedSecond % 10 {
            case 0...3:
                return "Inhale"
            default:
                return "Exhale"
            }
        case .equalBreath:
            switch elapsedSecond % 8 {
            case 0...3:
                return "Inhale"
            default:
                return "Exhale"
            }
        }
    }
}

/// Optional named ritual that maps to duration plus breathing style.
enum RitualPreset: String, CaseIterable, Identifiable {
    case reset
    case focus
    case unwind
    case sleepWindDown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reset:
            return "Reset"
        case .focus:
            return "Focus"
        case .unwind:
            return "Unwind"
        case .sleepWindDown:
            return "Sleep Wind Down"
        }
    }

    var durationMinutes: Int {
        switch self {
        case .reset:
            return 3
        case .focus:
            return 5
        case .unwind:
            return 10
        case .sleepWindDown:
            return 15
        }
    }

    var breathingStyle: BreathingStyle {
        switch self {
        case .reset:
            return .calmExhale
        case .focus:
            return .equalBreath
        case .unwind:
            return .quietTimer
        case .sleepWindDown:
            return .calmExhale
        }
    }
}

/// Optional one-tap reflection after a completed session.
enum SessionReflection: String, CaseIterable, Identifiable {
    case calm
    case okay
    case restless

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm:
            return "Calm"
        case .okay:
            return "Okay"
        case .restless:
            return "Restless"
        }
    }
}

/// Persisted record for a fully completed meditation session.
struct CompletedMeditationSessionRecord: Codable, Equatable {
    let startDate: Date
    let endDate: Date
    let plannedDuration: TimeInterval
}

enum CompletedSessionRecordMerger {
    static func normalized(
        _ records: [CompletedMeditationSessionRecord],
        maxCount: Int
    ) -> [CompletedMeditationSessionRecord] {
        guard maxCount > 0 else { return [] }

        let sorted = records.sorted { $0.endDate < $1.endDate }
        var unique: [CompletedMeditationSessionRecord] = []
        unique.reserveCapacity(sorted.count)

        for record in sorted {
            let duplicateExists = unique.contains { existing in
                isApproximatelyDuplicate(existing, record)
            }
            if !duplicateExists {
                unique.append(record)
            }
        }

        if unique.count > maxCount {
            return Array(unique.suffix(maxCount))
        }

        return unique
    }

    private static func isApproximatelyDuplicate(
        _ lhs: CompletedMeditationSessionRecord,
        _ rhs: CompletedMeditationSessionRecord
    ) -> Bool {
        abs(lhs.startDate.timeIntervalSince(rhs.startDate)) < 1 &&
        abs(lhs.endDate.timeIntervalSince(rhs.endDate)) < 1 &&
        abs(lhs.plannedDuration - rhs.plannedDuration) < 0.5
    }
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
