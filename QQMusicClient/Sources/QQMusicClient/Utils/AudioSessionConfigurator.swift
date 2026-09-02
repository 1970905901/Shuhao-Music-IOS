import AVFoundation
import MediaPlayer

public enum AudioSessionConfigurator {
    public static func configure() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
        }
    }
}
