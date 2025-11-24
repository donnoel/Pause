import Foundation
import Combine

final class SessionViewModel: ObservableObject {
    // Published state for the view
    @Published private(set) var state: SessionState = .idle
    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var total: TimeInterval = 0
    @Published private(set) var selectedPreset: SessionDurationPreset? = .ten
    @Published var isCustomDurationSheetPresented: Bool = false
    @Published private(set) var customDurationMinutes: Int = 10

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
    }

    // MARK: - Public API used by the view

    var presets: [SessionDurationPreset] {
        SessionDurationPreset.allCases
    }

    func startPreset(_ preset: SessionDurationPreset) {
        selectedPreset = preset
        let duration = preset.rawValue
        start(duration: duration, markAsPreset: true)
    }

    func startCustomDuration(minutes: Int) {
        // Clamp to at least 1 minute to avoid weirdness.
        customDurationMinutes = max(1, minutes)
        selectedPreset = nil
        let seconds = TimeInterval(customDurationMinutes * 60)
        start(duration: seconds, markAsPreset: false)
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
    }

    func resetCompletion() {
        // Called when user dismisses completion state
        cancel()
    }

    // MARK: - Private

    private func start(duration: TimeInterval, markAsPreset: Bool) {
        guard duration > 0 else { return }

        total = duration
        remaining = duration
        state = .running

        // Keep the app alive when the screen locks.
        backgroundAudio.startKeepingAlive()

        timerEngine.start(duration: duration)
    }

    private func handleCompletion() {
        state = .completed
        remaining = 0

        // End-of-session bell
        chimePlayer.play(chimeType: .end)

    }
}
