import Foundation
import AVFoundation

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

/// Concrete implementation that plays `Bell.mp3` from the main bundle.
final class SystemAudioChimePlayer: NSObject, AudioChimePlaying {

    private var audioPlayer: AVAudioPlayer?

    // If you ever change the file name/extension, just update these.
    private let fileName = "chime"
    private let fileExtension = "mp3"

    /// Master chime volume relative to system volume.
    /// 1.0 = full, 0.0 = silent. 0.25 is a "polite" chime.
    private let chimeVolume: Float = 0.10

    func play(chimeType: ChimeType) {
        // For now, both halfway + end use the same sound.
        // You could vary behavior later based on `chimeType` if you want.
        playBell()
    }

    private func playBell() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            #if DEBUG
            print("⚠️ SystemAudioChimePlayer: Could not find \(fileName).\(fileExtension) in bundle.")
            #endif
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = chimeVolume      // ⬅️ make the chime quieter
            player.prepareToPlay()
            player.play()
            audioPlayer = player             // keep a strong reference
        } catch {
            #if DEBUG
            print("⚠️ SystemAudioChimePlayer: Failed to play \(fileName).\(fileExtension): \(error)")
            #endif
        }
    }
}
