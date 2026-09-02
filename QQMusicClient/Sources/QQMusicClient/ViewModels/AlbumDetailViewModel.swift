import Foundation

@MainActor
final class AlbumDetailViewModel: ObservableObject {
    @Published private(set) var albumInfo: AlbumInfo?
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let apiService = QQMusicAPIService.shared

    func load(albumMid: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await apiService.fetchAlbumDetail(albumMid: albumMid)
                albumInfo = result.info
                songs = result.songs
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
