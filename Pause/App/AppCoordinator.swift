import SwiftUI
import Combine

final class AppCoordinator: ObservableObject {
    private let sessionCoordinator = SessionCoordinator()
    
    @ViewBuilder
    func rootView() -> some View {
        sessionCoordinator.makeView()
    }
}
