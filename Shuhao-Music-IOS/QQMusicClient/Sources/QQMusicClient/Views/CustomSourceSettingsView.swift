import SwiftUI

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

    private let service = CustomSourceService.shared

    func load() {
        Task {
            importedSource = await service.loadSource()
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
        }
    }
}
