import Foundation

@MainActor
final class PlaylistDetailViewModel: ObservableObject {
    @Published private(set) var playlist: Playlist?
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let apiService = QQMusicAPIService.shared

    func load(playlistID: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await apiService.fetchPlaylistDetail(id: playlistID)
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
