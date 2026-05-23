import Foundation
import Combine
import UIKit

@MainActor
final class SessionViewModel: ObservableObject {
    // Published state for the view
    @Published private(set) var state: SessionState = .idle
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var total: TimeInterval = 0
    @Published private(set) var selectedPreset: SessionDurationPreset? = .five
    @Published private(set) var selectedBreathingStyle: BreathingStyle = .quietTimer
    @Published private(set) var selectedRitualPreset: RitualPreset?
    @Published private(set) var selectedReflection: SessionReflection?
    @Published var isCustomDurationSheetPresented: Bool = false
    @Published private(set) var customDurationMinutes: Int = 5
    @Published private(set) var statsSummary: SessionStatsSummary = .empty
    @Published private(set) var activeSessionBreathingStyle: BreathingStyle?

    private let timerEngine: MeditationTimerEngineProtocol
    private let chimePlayer: AudioChimePlaying
    private let backgroundAudio: BackgroundAudioControlling
    private var sessionStartDate: Date?
    private var lifecycleCancellables: Set<AnyCancellable> = []

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
         backgroundAudio: BackgroundAudioControlling) {
        self.timerEngine = timerEngine
        self.chimePlayer = chimePlayer
        self.backgroundAudio = backgroundAudio

        timerEngine.onTick = { [weak self] remaining in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.remaining = max(remaining, 0)
            }
        }

        timerEngine.onHalfway = { [weak self] in
            Task { @MainActor [weak self] in
                self?.chimePlayer.play(chimeType: .halfway)
            }
        }

        timerEngine.onCompleted = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleCompletion()
            }
        }

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSceneDidBecomeActive()
            }
            .store(in: &lifecycleCancellables)

        restoreActiveSessionIfNeeded()
        refreshStats()
    }

    // MARK: - Public API used by the view

    var presets: [SessionDurationPreset] {
        SessionDurationPreset.allCases
    }

    var ritualPresets: [RitualPreset] {
        RitualPreset.allCases
    }

    var breathingStyles: [BreathingStyle] {
        BreathingStyle.allCases
    }

    var reflectionOptions: [SessionReflection] {
        SessionReflection.allCases
    }

    var selectedDuration: TimeInterval {
        if let preset = selectedPreset {
            return preset.rawValue
        }
        return TimeInterval(customDurationMinutes * 60)
    }

    var breathingStyleForCurrentSession: BreathingStyle {
        activeSessionBreathingStyle ?? selectedBreathingStyle
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
        guard canEditConfiguration else { return }
        selectedPreset = preset
        selectedRitualPreset = nil
    }

    func selectBreathingStyle(_ style: BreathingStyle) {
        guard canEditConfiguration else { return }
        selectedBreathingStyle = style
        selectedRitualPreset = nil
    }

    func selectRitualPreset(_ ritual: RitualPreset) {
        guard canEditConfiguration else { return }
        selectedRitualPreset = ritual
        selectedBreathingStyle = ritual.breathingStyle
        applyDurationSelection(minutes: ritual.durationMinutes)
    }

    func selectReflection(_ reflection: SessionReflection) {
        guard state == .completed else { return }
        selectedReflection = reflection
    }

    func startPreset(_ preset: SessionDurationPreset) {
        selectPreset(preset)
        let duration = preset.rawValue
        start(duration: duration)
    }

    func selectCustomDuration(minutes: Int) {
        guard canEditConfiguration else { return }
        applyDurationSelection(minutes: minutes)
        selectedRitualPreset = nil
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
        selectedReflection = nil
        activeSessionBreathingStyle = nil
        sessionStartDate = nil
        backgroundAudio.stopKeepingAlive()
        PauseSessionStore.clear()
    }

    func resetCompletion() {
        // Called when user dismisses completion state
        cancel()
    }

    func handleSceneDidBecomeActive() {
        guard state != .paused else { return }
        restoreActiveSessionIfNeeded()
    }

    private func restoreActiveSessionIfNeeded() {
        let info = PauseSessionStore.load()
        guard info.isActive, let end = info.endDate else { return }

        let now = Date()
        if now >= end {
            completeRestoredSession(info, endedAt: end)
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
        activeSessionBreathingStyle = activeSessionBreathingStyle ?? selectedBreathingStyle
        sessionStartDate = info.startDate

        timerEngine.start(duration: remainingInterval)
    }

    // MARK: - Private

    private func start(duration: TimeInterval) {
        guard duration > 0 else { return }

        total = duration
        remaining = duration
        state = .running
        selectedReflection = nil
        activeSessionBreathingStyle = selectedBreathingStyle

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

        backgroundAudio.startKeepingAlive()

        timerEngine.start(duration: duration)
    }

    private func applyDurationSelection(minutes: Int) {
        let clampedMinutes = max(1, minutes)
        customDurationMinutes = clampedMinutes

        if let matchingPreset = presets.first(where: { $0.minutes == clampedMinutes }) {
            selectedPreset = matchingPreset
        } else {
            selectedPreset = nil
        }
    }

    private var canEditConfiguration: Bool {
        state == .idle || state == .completed
    }

    private func completeRestoredSession(_ info: PauseSessionInfo, endedAt completionDate: Date) {
        timerEngine.cancel()
        state = .completed
        remaining = 0
        selectedReflection = nil

        let startedAt = info.startDate ?? completionDate
        let plannedDuration = max(0, completionDate.timeIntervalSince(startedAt))
        total = plannedDuration

        if plannedDuration > 0, completionDate > startedAt {
            PauseSessionStore.recordCompletedSession(
                startDate: startedAt,
                endDate: completionDate,
                plannedDuration: plannedDuration
            )
        }

        activeSessionBreathingStyle = nil
        sessionStartDate = nil
        PauseSessionStore.clear()
        refreshStats()
        backgroundAudio.stopKeepingAlive()
    }

    private func handleCompletion() {
        state = .completed
        remaining = 0
        selectedReflection = nil

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

        activeSessionBreathingStyle = nil
        sessionStartDate = nil
        PauseSessionStore.clear()
        refreshStats()

        // Keep the delayed stop so foreground chime playback is not interrupted
        // by a quickly restarted session.
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
