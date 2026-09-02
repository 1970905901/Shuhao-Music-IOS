import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        Group {
            if viewModel.songs.isEmpty {
                EmptyStateView(
                    systemImage: "heart",
                    title: "还没有收藏",
                    message: "在播放页或歌曲右键菜单中点击收藏，喜欢的歌会出现在这里"
                )
            } else {
                List(viewModel.songs) { song in
                    Button {
                        playerViewModel.play(song: song)
                    } label: {
                        SongRow(song: song)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
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
