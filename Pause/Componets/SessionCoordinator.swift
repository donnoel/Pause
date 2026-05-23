import SwiftUI
import Combine

final class SessionCoordinator: ObservableObject {
    @MainActor
    func makeView() -> some View {
        let timerEngine = MeditationTimerEngine()
        let chimePlayer: AudioChimePlaying = SystemAudioChimePlayer()
        let backgroundAudio: BackgroundAudioControlling = BackgroundAudioManager.shared
        let notificationScheduler: SessionNotificationScheduling = SessionNotificationScheduler()
        let viewModel = SessionViewModel(
            timerEngine: timerEngine,
            chimePlayer: chimePlayer,
            backgroundAudio: backgroundAudio,
            notificationScheduler: notificationScheduler
        )
        return SessionView(viewModel: viewModel)
    }
}
