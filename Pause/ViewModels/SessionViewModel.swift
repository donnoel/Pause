import Foundation
import Combine

final class SessionViewModel: ObservableObject {
    // Published state for the view
    @Published private(set) var state: SessionState = .idle
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var total: TimeInterval = 0
    @Published private(set) var selectedPreset: SessionDurationPreset? = .five
    @Published var isCustomDurationSheetPresented: Bool = false
    @Published private(set) var customDurationMinutes: Int = 5
    @Published private(set) var statsSummary: SessionStatsSummary = .empty

    private let timerEngine: MeditationTimerEngineProtocol
    private let chimePlayer: AudioChimePlaying
    private let backgroundAudio: BackgroundAudioControlling
    private var sessionStartDate: Date?

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Init

    init(timerEngine: MeditationTimerEngineProtocol,
         chimePlayer: AudioChimePlaying,
         backgroundAudio: BackgroundAudioControlling = BackgroundAudioManager.shared) {
        self.timerEngine = timerEngine
        self.chimePlayer = chimePlayer
        self.backgroundAudio = backgroundAudio

        timerEngine.onTick = { [weak self] remaining in
            guard let self = self else { return }
            self.remaining = max(remaining, 0)
        }

        timerEngine.onHalfway = { [weak self] in
            self?.chimePlayer.play(chimeType: .halfway)
        }

        timerEngine.onCompleted = { [weak self] in
            self?.handleCompletion()
        }

        restoreActiveSessionIfNeeded()
        refreshStats()
    }

    // MARK: - Public API used by the view

    var presets: [SessionDurationPreset] {
        SessionDurationPreset.allCases
    }

    var selectedDuration: TimeInterval {
        if let preset = selectedPreset {
            return preset.rawValue
        }
        return TimeInterval(customDurationMinutes * 60)
    }

    var completedSessionDates: Set<DateComponents> {
        statsSummary.completedDateComponents
    }

    var completedSessionCount: Int {
        statsSummary.completedSessionCount
    }

    var usualMeditationTimeDescription: String {
        guard let minutes = statsSummary.usualMeditationMinutesFromMidnight else {
            return "Not enough completed sessions yet."
        }

        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        components.second = 0

        guard let date = Calendar.current.date(from: components) else {
            return "Not enough completed sessions yet."
        }

        return Self.timeFormatter.string(from: date)
    }

    var lastMeditationDescription: String {
        guard let session = statsSummary.lastCompletedSession else {
            return "No completed sessions yet."
        }

        let completedAt = Self.dateTimeFormatter.string(from: session.endDate)
        let durationText = formatDurationForSummary(session.plannedDuration)
        return "\(completedAt) • \(durationText)"
    }

    var averageSessionLengthDescription: String {
        guard let averageLength = statsSummary.averageSessionLength else {
            return "No completed sessions yet."
        }

        return formatDurationForSummary(averageLength)
    }

    func selectPreset(_ preset: SessionDurationPreset) {
        selectedPreset = preset
    }

    func startPreset(_ preset: SessionDurationPreset) {
        selectPreset(preset)
        let duration = preset.rawValue
        start(duration: duration)
    }

    func selectCustomDuration(minutes: Int) {
        // Clamp to at least 1 minute to avoid weirdness.
        customDurationMinutes = max(1, minutes)
        selectedPreset = nil
    }

    func startCustomDuration(minutes: Int) {
        selectCustomDuration(minutes: minutes)
        let seconds = TimeInterval(customDurationMinutes * 60)
        start(duration: seconds)
    }

    func startSelectedSession() {
        start(duration: selectedDuration)
    }

    func togglePause() {
        switch state {
        case .running:
            timerEngine.pause()
            state = .paused
        case .paused:
            timerEngine.resume()
            state = .running
        default:
            break
        }
    }

    func cancel() {
        timerEngine.cancel()
        state = .idle
        remaining = 0
        total = 0
        sessionStartDate = nil
        backgroundAudio.stopKeepingAlive()
        PauseSessionStore.clear()
    }

    func resetCompletion() {
        // Called when user dismisses completion state
        cancel()
    }

    private func restoreActiveSessionIfNeeded() {
        let info = PauseSessionStore.load()
        guard info.isActive, let end = info.endDate else { return }

        let now = Date()
        if now >= end {
            // Session already finished – move to completed and clear store.
            state = .completed
            remaining = 0
            sessionStartDate = nil
            if let start = info.startDate {
                total = end.timeIntervalSince(start)
            }
            PauseSessionStore.clear()
            return
        }

        let remainingInterval = end.timeIntervalSince(now)
        let totalInterval: TimeInterval
        if let start = info.startDate {
            totalInterval = end.timeIntervalSince(start)
        } else {
            totalInterval = remainingInterval
        }

        total = totalInterval
        remaining = remainingInterval
        state = .running
        sessionStartDate = info.startDate

        backgroundAudio.startKeepingAlive()
        timerEngine.start(duration: remainingInterval)
    }

    // MARK: - Private

    private func start(duration: TimeInterval) {
        guard duration > 0 else { return }

        total = duration
        remaining = duration
        state = .running

        let startTime = Date()
        sessionStartDate = startTime
        let endTime = startTime.addingTimeInterval(duration)
        PauseSessionStore.save(
            PauseSessionInfo(
                isActive: true,
                startDate: startTime,
                endDate: endTime
            )
        )

        // Keep the app alive when the screen locks.
        backgroundAudio.startKeepingAlive()

        timerEngine.start(duration: duration)
    }

    private func handleCompletion() {
        state = .completed
        remaining = 0

        // End-of-session bell
        chimePlayer.play(chimeType: .end)

        let completionDate = Date()
        let startedAt = sessionStartDate ?? completionDate.addingTimeInterval(-total)
        if total > 0, completionDate > startedAt {
            PauseSessionStore.recordCompletedSession(
                startDate: startedAt,
                endDate: completionDate,
                plannedDuration: total
            )
        }

        sessionStartDate = nil
        PauseSessionStore.clear()
        refreshStats()

        // Allow the chime to ring out before stopping background keep-alive.
        // We only stop if we're still in the completed state to avoid
        // interfering with a quickly restarted session.
        let delay: TimeInterval = 3
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.state == .completed else { return }
            self.backgroundAudio.stopKeepingAlive()
        }
    }

    private func refreshStats() {
        let records = PauseSessionStore.loadCompletedSessions()
        statsSummary = SessionStatsCalculator.makeSummary(from: records)
    }

    private func formatDurationForSummary(_ duration: TimeInterval) -> String {
        let roundedSeconds = Int(duration.rounded())
        let minutes = roundedSeconds / 60
        let seconds = roundedSeconds % 60

        if minutes > 0, seconds == 0 {
            return "\(minutes) min"
        }

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(seconds)s"
    }
}
