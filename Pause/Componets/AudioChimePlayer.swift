import Foundation
import AVFoundation
import AudioToolbox

/// Types of chimes we support. Right now they both use the same sound,
/// but this makes it easy to swap them later if you want different bells.
enum ChimeType {
    case halfway
    case end
}

/// Abstraction so the view model doesn’t know *how* we play audio.
protocol AudioChimePlaying {
    func play(chimeType: ChimeType)
}

/// Concrete implementation that prefers a bundled `chime.mp3` and falls back
/// to a built-in system sound if the bundled file is unavailable.
final class SystemAudioChimePlayer: NSObject, AudioChimePlaying, AVAudioPlayerDelegate {

    private var audioPlayer: AVAudioPlayer?

    // If you ever change the file name/extension, just update these.
    private let fileName = "chime"
    private let fileExtension = "mp3"

    /// Master chime volume relative to system volume.
    /// 1.0 = full, 0.0 = silent. 0.25 is a "polite" chime.
    private let chimeVolume: Float = 0.15
    private let fallbackSystemSoundID: SystemSoundID = 1005

    func play(chimeType: ChimeType) {
        playBell()
    }

    private func playBell() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            #if DEBUG
            print("⚠️ SystemAudioChimePlayer: Could not find \(fileName).\(fileExtension) in bundle. Falling back to system sound.")
            #endif
            playFallbackSystemSound()
            return
        }

        do {
            try configureAudioSession()

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.volume = chimeVolume
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            #if DEBUG
            print("⚠️ SystemAudioChimePlayer: Failed to play \(fileName).\(fileExtension): \(error). Falling back to system sound.")
            #endif
            playFallbackSystemSound()
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true, options: [])
    }

    private func playFallbackSystemSound() {
        AudioServicesPlaySystemSound(fallbackSystemSoundID)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        deactivateAudioSessionIfPossible()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        audioPlayer = nil
        deactivateAudioSessionIfPossible()
    }

    private func deactivateAudioSessionIfPossible() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            #if DEBUG
            print("⚠️ SystemAudioChimePlayer: Failed to deactivate audio session: \(error)")
            #endif
        }
    }
}
