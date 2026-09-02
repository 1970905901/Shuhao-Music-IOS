import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public var body: some View {
        if horizontalSizeClass == .compact {
            NavigationView {
                sidebar

                PlayerView()
                    .navigationTitle("正在播放")
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            NavigationView {
                sidebar

                PlayerView()
                    .navigationTitle("正在播放")
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
        }
    }

    private var sidebar: some View {
        List {
            Section {
                NavigationLink(destination: SearchView().navigationTitle("搜索")) {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                NavigationLink(destination: PlaylistListView().navigationTitle("歌单")) {
                    Label("歌单", systemImage: "music.note.list")
                }
                NavigationLink(destination: PlayerView().navigationTitle("正在播放")) {
                    Label("正在播放", systemImage: "play.circle")
                }
                NavigationLink(destination: HistoryView().navigationTitle("播放历史")) {
                    Label("播放历史", systemImage: "clock")
                }
                NavigationLink(destination: FavoritesView().navigationTitle("我的收藏")) {
                    Label("我的收藏", systemImage: "heart")
                }
                NavigationLink(destination: CustomSourceSettingsView().navigationTitle("自定义音源")) {
                    Label("自定义音源", systemImage: "wand.and.stars")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("QQ 音乐")
    }
}
