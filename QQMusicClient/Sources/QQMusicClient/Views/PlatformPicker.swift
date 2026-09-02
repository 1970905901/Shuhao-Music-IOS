import SwiftUI

struct PlatformPicker: View {
    @ObservedObject private var store = PlatformStore.shared

    var body: some View {
        Picker("音乐平台", selection: $store.selectedPlatform) {
            ForEach(MusicPlatform.allCases) { platform in
                Text(platform.displayName).tag(platform)
            }
        }
        .pickerStyle(.menu)
    }
}
