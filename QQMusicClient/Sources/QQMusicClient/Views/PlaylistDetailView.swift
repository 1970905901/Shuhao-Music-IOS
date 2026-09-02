import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    @StateObject private var viewModel = PlaylistDetailViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PlatformPicker()
                Spacer()
            }
            .padding()

            List(viewModel.songs) { song in
                Button {
                    playerViewModel.play(song: song, queue: viewModel.songs)
                } label: {
                    SongRow(song: song)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(.plain)
        }
        .navigationTitle(playlist.name)
        .onAppear {
            if viewModel.songs.isEmpty {
                viewModel.load(playlistID: playlist.id)
            }
        }
        .onChange(of: viewModel.platform, perform: { _ in
            viewModel.load(playlistID: playlist.id)
        })
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let message = viewModel.unsupportedMessage {
                EmptyStateView(systemImage: "music.note.list", title: "暂不支持", message: message)
            } else if let error = viewModel.errorMessage {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "加载失败", message: error)
            } else if viewModel.songs.isEmpty {
                EmptyStateView(systemImage: "music.note", title: "暂无歌曲", message: nil)
            }
        }
    }
}
