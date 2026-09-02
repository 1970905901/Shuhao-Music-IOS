import Foundation
import Combine

@MainActor
final class PlaylistDetailViewModel: ObservableObject {
    @Published private(set) var playlist: Playlist?
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var platform: MusicPlatform = PlatformStore.shared.selectedPlatform

    private var service: any MusicPlatformService = MusicServiceFactory.service(for: PlatformStore.shared.selectedPlatform)
    private var cancellables = Set<AnyCancellable>()

    init() {
        PlatformStore.shared.$selectedPlatform
            .receive(on: DispatchQueue.main)
            .sink { [weak self] platform in
                self?.platform = platform
                self?.service = MusicServiceFactory.service(for: platform)
                self?.playlist = nil
                self?.songs = []
            }
            .store(in: &cancellables)
    }

    func load(playlistID: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await service.fetchPlaylistDetail(id: playlistID)
                playlist = result.playlist
                songs = result.songs
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
