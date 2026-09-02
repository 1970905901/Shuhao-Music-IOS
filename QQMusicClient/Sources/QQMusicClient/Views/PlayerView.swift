import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isFavorite = false

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 24) {
                    coverImage
                    trackInfo
                    progressSection
                    controlButtons
                    LyricView()
                        .frame(minHeight: 200)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .pink : .primary)
                    }
                    .disabled(viewModel.currentSong == nil)

                    NavigationLink(destination: QueueView()) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
        }
        .onAppear {
            updateFavoriteState()
        }
        .onChange(of: viewModel.currentSong, perform: { _ in
            updateFavoriteState()
        })
    }

    private func toggleFavorite() {
        guard let song = viewModel.currentSong else { return }
        Task {
            isFavorite = await HistoryService.shared.toggleFavorite(song: song)
        }
    }

    private func updateFavoriteState() {
        guard let song = viewModel.currentSong else {
            isFavorite = false
            return
        }
        Task {
            isFavorite = await HistoryService.shared.isFavorite(song: song)
        }
    }

    private var background: some View {
        Color.clear
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
    }

    private var coverImage: some View {
        AsyncImage(url: viewModel.currentSong?.coverURL) { image in
            image.resizable().aspectRatio(contentMode: .fit)
        } placeholder: {
            Color.secondary.opacity(0.2)
        }
        .frame(maxWidth: horizontalSizeClass == .compact ? 280 : 360)
        .cornerRadius(16)
        .shadow(radius: 12)
    }

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(viewModel.currentSong?.name ?? "未在播放")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(viewModel.currentSong?.displayArtist ?? "选择一首歌曲开始播放")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...max(viewModel.duration, 1)
            )
            .accentColor(.pink)

            HStack {
                Text(viewModel.formattedCurrentTime)
                Spacer()
                Text(viewModel.formattedDuration)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 40) {
            Button {
                viewModel.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
            }
            .disabled(viewModel.currentIndex <= 0)

            Button {
                viewModel.playPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }
            .disabled(viewModel.currentSong == nil)

            Button {
                viewModel.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
            }
            .disabled(viewModel.currentIndex + 1 >= viewModel.queue.count)
        }
        .foregroundColor(.primary)
    }
}
