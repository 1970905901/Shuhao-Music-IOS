import Foundation

/// 自定义音源管理器：支持导入 LxMusic JS 源，并复现其获取音乐 URL 的逻辑
actor CustomSourceService {
    static let shared = CustomSourceService()

    private let sourceKey = "qqmusic.lx.source"
    private let session = URLSession.shared

    private init() {}

    // MARK: - Persistence

    func saveSource(_ source: ParsedLxMusicSource) {
        guard let data = try? JSONEncoder().encode(source) else { return }
        UserDefaults.standard.set(data, forKey: sourceKey)
    }

    func loadSource() -> ParsedLxMusicSource? {
        guard let data = UserDefaults.standard.data(forKey: sourceKey),
              let source = try? JSONDecoder().decode(ParsedLxMusicSource.self, from: data) else {
            return nil
        }
        return source
    }

    func deleteSource() {
        UserDefaults.standard.removeObject(forKey: sourceKey)
    }

    // MARK: - Playback URL

    /// 使用已导入的自定义源获取指定歌曲的播放 URL
    func audioURL(for song: Song, platform: MusicPlatform, quality: String = "flac") async throws -> URL {
        guard let source = loadSource() else {
            throw QQMusicError.noAudioURL
        }
        return try await audioURL(for: song, platform: platform, source: source, quality: quality)
    }

    func audioURL(for song: Song, platform: MusicPlatform, source: ParsedLxMusicSource, quality: String) async throws -> URL {
        let sourceCode = platform.sourceCode
        let songId = song.mid

        guard let url = URL(string: "\(source.apiURL)/music/url") else {
            throw QQMusicError.invalidURL
        }

        let body: [String: Any] = [
            "source": sourceCode,
            "musicId": songId,
            "quality": quality
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw QQMusicError.decodeFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("lx-music-mobile/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(source.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.httpBody = bodyData
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? Int else {
            throw QQMusicError.decodeFailed
        }

        switch code {
        case 200:
            guard let urlString = json["url"] as? String,
                  let audioURL = URL(string: urlString) else {
                throw QQMusicError.noAudioURL
            }
            return audioURL
        case 403:
            throw QQMusicError.custom(message: "Key失效/鉴权失败")
        case 429:
            throw QQMusicError.custom(message: "请求过速")
        case 500:
            let message = json["message"] as? String ?? "未知错误"
            throw QQMusicError.custom(message: "获取URL失败: \(message)")
        default:
            let message = json["message"] as? String ?? "未知错误"
            throw QQMusicError.custom(message: message)
        }
    }

    // MARK: - Helpers

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QQMusicError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw QQMusicError.requestFailed(httpResponse.statusCode)
        }
    }
}
