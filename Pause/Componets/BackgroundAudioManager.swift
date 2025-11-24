import Foundation
import AVFoundation

/// Simple abstraction so we can stub this out in tests if needed.
protocol BackgroundAudioControlling {
    func startKeepingAlive()
    func stopKeepingAlive()
}

/// Keeps the app alive while a session is running by playing a silent audio stream.
/// Uses the "audio" background mode so timers & chimes keep working when the screen is locked.
final class BackgroundAudioManager: BackgroundAudioControlling {

    static let shared = BackgroundAudioManager()

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    private var isConfigured = false

    private init() {}

    // MARK: - Public API

    /// Call when a meditation session starts.
    func startKeepingAlive() {
        configureIfNeeded()
        ensureEngineRunning()
    }

    /// Call when a meditation session ends or is cancelled.
    func stopKeepingAlive() {
        guard isConfigured else { return }

        engine.pause()

        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
        } catch {
            #if DEBUG
            print("⚠️ BackgroundAudioManager: Failed to deactivate audio session: \(error)")
            #endif
        }
    }

    // MARK: - Private

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        let session = AVAudioSession.sharedInstance()

        do {
            // playback: allows background audio
            // mixWithOthers: don't stomp on Spotify / Apple Music
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("⚠️ BackgroundAudioManager: Failed to configure AVAudioSession: \(error)")
            #endif
        }

        let outputFormat = engine.outputNode.outputFormat(forBus: 0)

        // Source node that outputs silence.
        let source = AVAudioSourceNode { _, _, _, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for bufferIndex in 0..<ablPointer.count {
                let buffer = ablPointer[bufferIndex]
                if let mData = buffer.mData {
                    memset(mData, 0, Int(buffer.mDataByteSize))
                }
            }
            // 0 == noErr
            return 0
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: outputFormat)

        sourceNode = source
        isConfigured = true

        ensureEngineRunning()
    }

    private func ensureEngineRunning() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
        } catch {
            #if DEBUG
            print("⚠️ BackgroundAudioManager: Failed to start AVAudioEngine: \(error)")
            #endif
        }
    }
}
