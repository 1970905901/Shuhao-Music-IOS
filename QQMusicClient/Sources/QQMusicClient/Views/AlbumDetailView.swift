import SwiftUI

struct AlbumDetailView: View {
    let albumMid: String
    @StateObject private var viewModel = AlbumDetailViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        List(viewModel.songs) { song in
            Button {
                playerViewModel.play(song: song, queue: viewModel.songs)
            } label: {
                SongRow(song: song)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(.plain)
        .navigationTitle(viewModel.albumInfo?.name ?? "专辑")
        .onAppear {
            if viewModel.songs.isEmpty {
                viewModel.load(albumMid: albumMid)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}
