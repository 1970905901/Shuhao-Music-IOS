import Foundation
import Combine

@MainActor
final class LeaderboardListViewModel: ObservableObject {
    @Published var leaderboards: [Playlist] = []
    @Published var isLoading = false
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
                self?.leaderboards = []
            }
            .store(in: &cancellables)
    }

    func load() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let list = try await service.fetchLeaderboards()
                leaderboards = list
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
