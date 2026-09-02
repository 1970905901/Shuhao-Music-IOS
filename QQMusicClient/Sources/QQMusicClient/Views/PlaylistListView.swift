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
        .onChange(of: viewModel.platform, perform: { _ in
            viewModel.load()
        })
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let message = viewModel.unsupportedMessage {
                EmptyStateView(systemImage: "music.note.list", title: "暂不支持", message: message)
            } else if let error = viewModel.errorMessage {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "加载失败", message: error)
            } else if viewModel.playlists.isEmpty {
                EmptyStateView(systemImage: "music.note.list", title: "暂无歌单", message: nil)
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
