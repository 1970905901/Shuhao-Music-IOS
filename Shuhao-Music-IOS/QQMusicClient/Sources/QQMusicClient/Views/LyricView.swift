import SwiftUI

struct LyricView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.lyrics.isEmpty {
                Text("暂无歌词")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(viewModel.lyrics.enumerated()), id: \.element.id) { index, line in
                                Text(line.text)
                                    .font(.body)
                                    .foregroundColor(index == viewModel.currentLyricIndex ? .primary : .secondary)
                                    .scaleEffect(index == viewModel.currentLyricIndex ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentLyricIndex)
                                    .id(index)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.currentLyricIndex, perform: { newValue in
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    })
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
