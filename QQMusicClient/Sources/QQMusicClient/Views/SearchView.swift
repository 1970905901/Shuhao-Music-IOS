import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PlatformPicker()
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            searchBar

            if viewModel.isLoading {
                ProgressView()
                    .padding()
                Spacer()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
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
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索歌曲、歌手", text: $viewModel.keyword)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.search()
                }
            if !viewModel.keyword.isEmpty {
                Button {
                    viewModel.keyword = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            Button("搜索") {
                viewModel.search()
            }
            .disabled(viewModel.keyword.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: song.coverURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.name)
                    .font(.body)
                    .lineLimit(1)
                Text(song.displayArtist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(song.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            // 平台未接入专辑/歌手时隐藏入口，避免进入必然失败的详情页
            if let albumMid = song.album?.mid, !albumMid.isEmpty, song.platform.supports(.album) {
                NavigationLink(destination: AlbumDetailView(albumMid: albumMid)) {
                    Label("查看专辑", systemImage: "square.stack")
                }
            }
            if let singerMid = song.singers.first?.mid, !singerMid.isEmpty, song.platform.supports(.artist) {
                NavigationLink(destination: ArtistDetailView(singerMid: singerMid)) {
                    Label("查看歌手", systemImage: "person")
                }
            }
        }
    }
}
