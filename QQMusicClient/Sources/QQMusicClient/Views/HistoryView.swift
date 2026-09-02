import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @EnvironmentObject private var playerViewModel: PlayerViewModel

    var body: some View {
        List(viewModel.items) { item in
            Button {
                playerViewModel.play(song: item.song)
            } label: {
                SongRow(song: item.song)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.load()
        }
        .navigationTitle("播放历史")
        .onAppear {
            viewModel.load()
        }
    }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []

    func load() {
        Task {
            items = await HistoryService.shared.loadHistory()
        }
    }
}
