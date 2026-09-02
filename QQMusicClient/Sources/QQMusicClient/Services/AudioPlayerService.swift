import AVFoundation
import MediaPlayer
import Combine
import UIKit

@MainActor
final class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentSong: Song?

    let playbackFinished = PassthroughSubject<Void, Never>()

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    private var currentArtwork: MPMediaItemArtwork?

    private init() {
        setupRemoteCommands()
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    func play(song: Song, url: URL) {
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        currentSong = song
        currentArtwork = nil

        addPeriodicTimeObserver()
        observePlaybackEnd()
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
        loadArtwork(for: song)
    }

    func playPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }

    func seek(to time: TimeInterval) {
        let target = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentSong = nil
        currentTime = 0
        duration = 0
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func observePlaybackEnd() {
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isPlaying = false
                self?.playbackFinished.send()
            }
        }
    }

    private func addPeriodicTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds
                if let item = self.player?.currentItem,
                   item.duration.isValid,
                   item.duration != .indefinite {
                    self.duration = item.duration.seconds
                } else {
                    self.duration = 0
                }
                self.updateNowPlayingInfo()
            }
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.playPause()
            }
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.playPause()
            }
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.playPause()
            }
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in
                self?.seek(to: event.positionTime)
            }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.name,
            MPMediaItemPropertyArtist: song.displayArtist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let artwork = currentArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork(for song: Song) {
        guard let url = song.coverURL else { return }
        Task { [weak self] @MainActor in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let self = self,
                      self.currentSong?.id == song.id,
                      let image = UIImage(data: data) else { return }
                self.currentArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                self.updateNowPlayingInfo()
            } catch {
                // 封面下载失败不影响播放，静默忽略
            }
        }
    }
}
