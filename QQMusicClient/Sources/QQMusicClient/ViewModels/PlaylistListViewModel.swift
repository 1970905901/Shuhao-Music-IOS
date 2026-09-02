import Foundation

@MainActor
final class PlaylistListViewModel: ObservableObject {
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let apiService = QQMusicAPIService.shared

    func load() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                playlists = try await apiService.fetchPlaylists()
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
