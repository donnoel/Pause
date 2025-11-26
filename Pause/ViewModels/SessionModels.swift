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
