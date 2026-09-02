import SwiftUI
import Combine

struct CustomSourceSettingsView: View {
    @StateObject private var viewModel = CustomSourceSettingsViewModel()

    var body: some View {
        Form {
            Section("已导入音源") {
                if let source = viewModel.importedSource {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(source.name)
                            .font(.body.bold())
                        Text(source.apiURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("支持平台: \(source.qualitys.keys.sorted().joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("未导入音源")
                        .foregroundColor(.secondary)
                }
            }

            Section("导入 LxMusic 音源") {
                TextEditor(text: $viewModel.scriptText)
                    .frame(minHeight: 180)
                    .font(.system(.body, design: .monospaced))

                Button {
                    viewModel.importFromText()
                } label: {
                    Text("解析并导入")
                }
                .disabled(viewModel.scriptText.isEmpty)

                if let message = viewModel.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(viewModel.isError ? .red : .green)
                }
            }

            if viewModel.importedSource != nil {
                Section("播放音质") {
                    Picker("音质", selection: $viewModel.preferredQuality) {
                        Text(QualityPreference.displayName(QualityPreference.auto)).tag(QualityPreference.auto)
                        ForEach(viewModel.availableQualities, id: \.self) { quality in
                            Text(QualityPreference.displayName(quality)).tag(quality)
                        }
                    }
                    .onChange(of: viewModel.preferredQuality) { newValue in
                        viewModel.selectQuality(newValue)
                    }

                    Text("当前平台：\(viewModel.qualityPlatform.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if viewModel.availableQualities.isEmpty {
                        Text("当前音源未声明该平台支持的音质，播放会直接失败")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        viewModel.deleteSource()
                    } label: {
                        Text("删除已导入音源")
                    }
                }
            }
        }
        .navigationTitle("自定义音源")
        .onAppear {
            viewModel.load()
        }
    }
}

@MainActor
final class CustomSourceSettingsViewModel: ObservableObject {
    @Published var scriptText = ""
    @Published var importedSource: ParsedLxMusicSource?
    @Published var message: String?
    @Published var isError = false
    @Published var availableQualities: [String] = []
    @Published var preferredQuality: String = QualityPreference.auto
    @Published private(set) var qualityPlatform: MusicPlatform = PlatformStore.shared.selectedPlatform

    private let service = CustomSourceService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        PlatformStore.shared.$selectedPlatform
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.refreshQualities() }
            }
            .store(in: &cancellables)
    }

    func load() {
        Task {
            importedSource = await service.loadSource()
            await refreshQualities()
        }
    }

    func refreshQualities() async {
        let platform = PlatformStore.shared.selectedPlatform
        qualityPlatform = platform
        guard let source = await service.loadSource() else {
            availableQualities = []
            preferredQuality = QualityPreference.auto
            return
        }
        availableQualities = await service.availableQualities(for: platform, source: source)
        preferredQuality = await service.preferredQuality() ?? QualityPreference.auto
    }

    func selectQuality(_ quality: String) {
        Task {
            await service.setPreferredQuality(quality)
        }
    }

    func importFromText() {
        do {
            let source = try LxMusicSourceParser.parse(script: scriptText)
            Task {
                await service.saveSource(source)
                importedSource = source
                message = "导入成功"
                isError = false
                scriptText = ""
                await refreshQualities()
            }
        } catch {
            message = "解析失败: \(error.localizedDescription)"
            isError = true
        }
    }

    func deleteSource() {
        Task {
            await service.deleteSource()
            importedSource = nil
            message = "已删除"
            isError = false
            await refreshQualities()
        }
    }
}
