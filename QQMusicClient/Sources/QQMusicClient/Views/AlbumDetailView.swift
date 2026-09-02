import SwiftUI

struct AlbumDetailView: View {
    let albumMid: String
    @StateObject private var viewModel = AlbumDetailViewModel()
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
        .navigationTitle(viewModel.albumInfo?.name ?? "专辑")
        .onAppear {
            if viewModel.songs.isEmpty {
                viewModel.load(albumMid: albumMid)
            }
        }
        .onChange(of: viewModel.platform) { _ in
            viewModel.load(albumMid: albumMid)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let message = viewModel.unsupportedMessage {
                EmptyStateView(systemImage: "square.stack", title: "暂不支持", message: message)
            } else if let error = viewModel.errorMessage {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "加载失败", message: error)
            } else if viewModel.songs.isEmpty {
                EmptyStateView(systemImage: "music.note", title: "暂无歌曲", message: nil)
            }
        }
    }
}
