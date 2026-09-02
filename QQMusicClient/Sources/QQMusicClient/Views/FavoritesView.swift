import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        List(viewModel.songs) { song in
            Button {
                playerViewModel.play(song: song)
            } label: {
                SongRow(song: song)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.load()
        }
        .navigationTitle("我的收藏")
        .onAppear {
            viewModel.load()
        }
    }
}

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var songs: [Song] = []

    func load() {
        Task {
            songs = await HistoryService.shared.loadFavorites()
        }
    }
}
