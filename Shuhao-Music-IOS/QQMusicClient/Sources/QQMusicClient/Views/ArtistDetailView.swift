import SwiftUI

struct ArtistDetailView: View {
    let singerMid: String
    @StateObject private var viewModel = ArtistDetailViewModel()
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
        .navigationTitle(viewModel.artistInfo?.name ?? "歌手")
        .onAppear {
            if viewModel.songs.isEmpty {
                viewModel.load(singerMid: singerMid)
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
