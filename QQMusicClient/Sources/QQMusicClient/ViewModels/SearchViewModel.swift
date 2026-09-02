import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var keyword = ""
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
                self?.songs = []
            }
            .store(in: &cancellables)
    }

    func search() {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                songs = try await service.search(keyword: keyword)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
