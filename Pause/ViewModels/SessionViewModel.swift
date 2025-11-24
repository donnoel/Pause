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
    
    init(timerEngine: MeditationTimerEngineProtocol,
         chimePlayer: AudioChimePlaying) {
        self.timerEngine = timerEngine
        self.chimePlayer = chimePlayer
        timerEngine.onTick = { [weak self] remaining in
            guard let self = self else { return }
            self.remaining = remaining
        }
        
        timerEngine.onHalfway = { [weak self] in
            self?.chimePlayer.play(chimeType: .halfway)
        }
        
        timerEngine.onCompleted = { [weak self] in
            guard let self = self else { return }
            self.state = .completed
            self.remaining = 0
            self.chimePlayer.play(chimeType: .end)
        }
    }
    
    // MARK: - Public API
    
    var presets: [SessionDurationPreset] {
        SessionDurationPreset.allCases
    }
    
    func startPreset(_ preset: SessionDurationPreset) {
        selectedPreset = preset
        let duration = preset.rawValue
        start(duration: duration, markAsPreset: true)
    }
    
    func startCustomDuration(minutes: Int) {
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
    }
    
    func resetCompletion() {
        // Called when user dismisses completion state
        cancel()
    }
    
    // MARK: - Private
    
    private func start(duration: TimeInterval, markAsPreset: Bool) {
        timerEngine.start(duration: duration)
        total = duration
        remaining = duration
        state = .running
    }
}
