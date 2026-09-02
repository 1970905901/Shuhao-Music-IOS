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

    func hasSource() -> Bool {
        loadSource() != nil
    }

    // MARK: - Playback URL

    /// 使用已导入的自定义源获取指定歌曲的播放 URL，音质由音源在该平台的支持情况决定
    func audioURL(for song: Song, platform: MusicPlatform) async throws -> URL {
        guard let source = loadSource() else {
            throw QQMusicError.noAudioURL
        }
        guard let quality = resolvedQuality(for: platform, source: source) else {
            throw QQMusicError.custom(message: "当前音源不支持 \(platform.displayName)")
        }
        return try await audioURL(for: song, platform: platform, source: source, quality: quality)
    }

    /// 音质优先级（由高到低），未手动指定时取该平台可用的最高音质
    /// 与 LxMusic 一致：master 母带 > atmos_plus > atmos > hires > flac > 999k > 320k > 192k > 128k
    private static let qualityPriority = ["master", "atmos_plus", "atmos", "hires", "flac", "999k", "320k", "192k", "128k"]

    /// 按音源在该平台声明的可用音质解析实际请求用的 quality，源不支持该平台时返回 nil
    func resolvedQuality(for platform: MusicPlatform, source: ParsedLxMusicSource) -> String? {
        let available = source.qualitys[platform.sourceCode] ?? []
        guard !available.isEmpty else { return nil }
        if let preferred = preferredQuality(), available.contains(preferred) { return preferred }
        for level in Self.qualityPriority where available.contains(level) { return level }
        return available.first
    }

    /// 当前音源在该平台支持的音质（按音质从高到低），供设置页展示与选择
    func availableQualities(for platform: MusicPlatform, source: ParsedLxMusicSource) -> [String] {
        let available = source.qualitys[platform.sourceCode] ?? []
        return available.sorted { Self.rank($0) < Self.rank($1) }
    }

    func preferredQuality() -> String? {
        let stored = UserDefaults.standard.string(forKey: QualityPreference.storageKey)
        return (stored?.isEmpty ?? true) ? nil : stored
    }

    func setPreferredQuality(_ quality: String?) {
        if let quality = quality, !quality.isEmpty, quality != QualityPreference.auto {
            UserDefaults.standard.set(quality, forKey: QualityPreference.storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: QualityPreference.storageKey)
        }
    }

    private static func rank(_ quality: String) -> Int {
        qualityPriority.firstIndex(of: quality) ?? qualityPriority.count
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
