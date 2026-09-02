import SwiftUI

struct QueueView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel

    var body: some View {
        List {
            ForEach(Array(viewModel.queue.enumerated()), id: \.element.id) { index, song in
                Button {
                    viewModel.play(song: song, queue: viewModel.queue)
                } label: {
                    HStack {
                        Text(song.name)
                            .font(.body)
                        if index == viewModel.currentIndex {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.pink)
                                .font(.caption)
                        }
                        Spacer()
                        Text(song.displayArtist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(.plain)
        .navigationTitle("播放队列")
    }
}
