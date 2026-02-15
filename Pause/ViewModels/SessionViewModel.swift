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

    private let timerEngine: MeditationTimerEngineProtocol
    private let chimePlayer: AudioChimePlaying
    private let backgroundAudio: BackgroundAudioControlling

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
    }

    // MARK: - Public API used by the view

    var presets: [SessionDurationPreset] {
        SessionDurationPreset.allCases
    }

    func startPreset(_ preset: SessionDurationPreset) {
        selectedPreset = preset
        let duration = preset.rawValue
        start(duration: duration)
    }

    func startCustomDuration(minutes: Int) {
        // Clamp to at least 1 minute to avoid weirdness.
        customDurationMinutes = max(1, minutes)
        selectedPreset = nil
        let seconds = TimeInterval(customDurationMinutes * 60)
        start(duration: seconds)
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

        PauseSessionStore.clear()

        // Allow the chime to ring out before stopping background keep-alive.
        // We only stop if we're still in the completed state to avoid
        // interfering with a quickly restarted session.
        let delay: TimeInterval = 3
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.state == .completed else { return }
            self.backgroundAudio.stopKeepingAlive()
        }
    }
}

