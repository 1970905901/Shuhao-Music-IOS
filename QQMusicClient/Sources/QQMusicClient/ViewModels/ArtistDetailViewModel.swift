import Foundation

@MainActor
final class ArtistDetailViewModel: ObservableObject {
    @Published private(set) var artistInfo: ArtistInfo?
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let apiService = QQMusicAPIService.shared

    func load(singerMid: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await apiService.fetchArtistDetail(singerMid: singerMid)
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
