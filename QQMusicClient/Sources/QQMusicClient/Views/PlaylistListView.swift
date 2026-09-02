import SwiftUI

struct PlaylistListView: View {
    @StateObject private var viewModel = PlaylistListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PlatformPicker()
                Spacer()
            }
            .padding()

            List(viewModel.playlists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    PlaylistRow(playlist: playlist)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("歌单")
        .onAppear {
            viewModel.load()
        }
        .onChange(of: viewModel.platform) { _ in
            viewModel.load()
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

struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: playlist.coverURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.name)
                    .font(.body)
                    .lineLimit(2)
                if let count = playlist.songCount {
                    Text("\(count) 首")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
