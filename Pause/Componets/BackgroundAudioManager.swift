import Foundation

/// Simple abstraction so we can stub this out in tests if needed.
protocol BackgroundAudioControlling {
    func startKeepingAlive()
    func stopKeepingAlive()
}

/// Compatibility shim kept so session flows can call into a background-audio controller
/// without relying on unsupported silent playback.
final class BackgroundAudioManager: BackgroundAudioControlling {

    static let shared = BackgroundAudioManager()

    private init() {}

    func startKeepingAlive() {}

    func stopKeepingAlive() {}
}
