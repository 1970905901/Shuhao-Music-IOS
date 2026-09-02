import Foundation
import Combine

@MainActor
final class ArtistDetailViewModel: ObservableObject {
    @Published private(set) var artistInfo: ArtistInfo?
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var unsupportedMessage: String?
    @Published private(set) var platform: MusicPlatform = PlatformStore.shared.selectedPlatform

    private var service: any MusicPlatformService = MusicServiceFactory.service(for: PlatformStore.shared.selectedPlatform)
    private var cancellables = Set<AnyCancellable>()

    init() {
        PlatformStore.shared.$selectedPlatform
            .receive(on: DispatchQueue.main)
            .sink { [weak self] platform in
                self?.platform = platform
                self?.service = MusicServiceFactory.service(for: platform)
                self?.artistInfo = nil
                self?.songs = []
                self?.unsupportedMessage = platform.supports(.artist) ? nil : platform.unsupportedMessage(.artist)
            }
            .store(in: &cancellables)
    }

    func load(singerMid: String) {
        guard platform.supports(.artist) else {
            songs = []
            isLoading = false
            unsupportedMessage = platform.unsupportedMessage(.artist)
            return
        }
        unsupportedMessage = nil
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await service.fetchArtistDetail(singerMid: singerMid)
                artistInfo = result.info
                songs = result.songs
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
