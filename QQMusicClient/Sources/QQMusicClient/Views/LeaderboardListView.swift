import SwiftUI

struct LeaderboardListView: View {
    @StateObject private var viewModel = LeaderboardListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PlatformPicker()
                Spacer()
            }
            .padding()

            List(viewModel.leaderboards) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    PlaylistRow(playlist: playlist)
                }
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.load()
            }
        }
        .navigationTitle("排行榜")
        .onAppear {
            viewModel.load()
        }
        .onChange(of: viewModel.platform, perform: { _ in
            viewModel.load()
        })
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                EmptyStateView(systemImage: "exclamationmark.triangle", title: "加载失败", message: error)
            } else if viewModel.leaderboards.isEmpty {
                EmptyStateView(systemImage: "chart.bar", title: "暂无榜单", message: nil)
            }
        }
    }
}
