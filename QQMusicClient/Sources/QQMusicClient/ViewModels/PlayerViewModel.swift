import Foundation
import Combine

@MainActor
public final class PlayerViewModel: ObservableObject {
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var lyrics: [LyricLine] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var queue: [Song] = []
    @Published private(set) var currentIndex: Int = -1
    @Published private(set) var platform: MusicPlatform = PlatformStore.shared.selectedPlatform

    private let customSourceService = CustomSourceService.shared
    private let audioService = AudioPlayerService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        audioService.$currentSong
            .receive(on: DispatchQueue.main)
            .sink { [weak self] song in
                self?.currentSong = song
                if let song = song {
                    self?.loadLyric(for: song)
                }
            }
            .store(in: &cancellables)

        audioService.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isPlaying = value
            }
            .store(in: &cancellables)

        audioService.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.currentTime = value
            }
            .store(in: &cancellables)

        audioService.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.duration = value
            }
            .store(in: &cancellables)

        audioService.playbackFinished
            .sink { [weak self] in
                self?.next()
            }
            .store(in: &cancellables)

        PlatformStore.shared.$selectedPlatform
            .receive(on: DispatchQueue.main)
            .sink { [weak self] platform in
                self?.platform = platform
            }
            .store(in: &cancellables)
    }

    func play(song: Song, queue: [Song]? = nil) {
        if let queue = queue {
            self.queue = queue
            self.currentIndex = queue.firstIndex(where: { $0.id == song.id }) ?? 0
        } else {
            self.queue = [song]
            self.currentIndex = 0
        }
        Task {
            await HistoryService.shared.addToHistory(song: song)
        }
        loadAndPlay(song: song)
    }

    func playPause() {
        audioService.playPause()
    }

    func seek(to time: TimeInterval) {
        audioService.seek(to: time)
    }

    func next() {
        guard currentIndex + 1 < queue.count else { return }
        currentIndex += 1
        loadAndPlay(song: queue[currentIndex])
    }

    func previous() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        loadAndPlay(song: queue[currentIndex])
    }

    func stop() {
        audioService.stop()
        lyrics = []
        queue = []
        currentIndex = -1
    }

    private func loadAndPlay(song: Song) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let url = try await resolveAudioURL(for: song)
                await audioService.play(song: song, url: url)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 播放链接统一来自自定义音源：按歌曲自身所属平台选择 sourceCode，
    /// 避免历史/收藏中的跨平台歌曲被当前平台误解析。
    private func resolveAudioURL(for song: Song) async throws -> URL {
        let hasSource = await customSourceService.hasSource()
        guard hasSource else {
            throw QQMusicError.custom(message: "未导入自定义音源，请前往「自定义音源」导入 LxMusic JS 源后再播放")
        }
        return try await customSourceService.audioURL(for: song, platform: song.platform)
    }

    private func loadLyric(for song: Song) {
        lyrics = []
        let service = MusicServiceFactory.service(for: song.platform)
        Task {
            do {
                lyrics = try await service.lyric(for: song.mid)
            } catch {
                lyrics = []
            }
        }
    }

    var currentLyricIndex: Int {
        guard !lyrics.isEmpty else { return 0 }
        let index = lyrics.lastIndex { $0.time <= currentTime } ?? 0
        return index
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite && time > 0 else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
