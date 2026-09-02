import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var keyword = ""
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var hasSearched = false
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
                self?.hasSearched = false
                self?.errorMessage = nil
            }
            .store(in: &cancellables)

        $keyword
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .sink { [weak self] keyword in
                self?.performSearch(keyword: keyword)
            }
            .store(in: &cancellables)
    }

    func search() {
        performSearch(keyword: keyword)
    }

    private func performSearch(keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                songs = try await service.search(keyword: trimmed)
                isLoading = false
                hasSearched = true
            } catch {
                isLoading = false
                hasSearched = true
                errorMessage = error.localizedDescription
            }
        }
    }
}
