import SwiftUI
import Combine

final class SessionCoordinator: ObservableObject {
    func makeView() -> some View {
        let timerEngine = MeditationTimerEngine()
        let chimePlayer: AudioChimePlaying = SystemAudioChimePlayer()
        let viewModel = SessionViewModel(timerEngine: timerEngine,
                                         chimePlayer: chimePlayer)
        return SessionView(viewModel: viewModel)
    }
}
