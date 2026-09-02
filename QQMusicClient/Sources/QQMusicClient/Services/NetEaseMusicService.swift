import Foundation

/// 网易云音乐服务
/// 使用公开 API 端点（无需 weapi 加密），实际稳定性以官方为准。
actor NetEaseMusicService: MusicPlatformService {
    static let shared = NetEaseMusicService()

    var platform: MusicPlatform { .netease }

    private let session = URLSession.shared

    func search(keyword: String, page: Int = 1, pageSize: Int = 20) async throws -> [Song] {
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw QQMusicError.invalidURL
        }
        let offset = (page - 1) * pageSize
        let urlString = "https://music.163.com/api/search/get/web?csrf_token=&hlpretag=&hlposttag=&s=\(encodedKeyword)&type=1&offset=\(offset)&total=true&limit=\(pageSize)"
        guard let url = URL(string: urlString) else {
            throw QQMusicError.invalidURL
        }

        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let songs = result["songs"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return songs.compactMap { item -> Song? in
            guard let id = item["id"] as? Int,
                  let name = item["name"] as? String else { return nil }
            let artists = (item["artists"] as? [[String: Any]]) ?? []
            let singerName = artists.compactMap { $0["name"] as? String }.joined(separator: " / ")
            let album = item["album"] as? [String: Any]
            let albumName = album?["name"] as? String ?? ""
            let albumId = album?["id"] as? Int
            let duration = item["duration"] as? Int ?? (item["dt"] as? Int)

            return Song(
                id: String(id),
                mid: String(id),
                name: name,
                subtitle: nil,
                album: Album(id: albumId.map(String.init), mid: nil, name: albumName),
                singers: [Singer(id: nil, mid: nil, name: singerName)],
                duration: duration.map { $0 / 1000 },
                coverURL: nil
            )
        }
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        let urlString = "https://music.163.com/api/song/lyric?os=pc&id=\(songMid)&lv=-1&kv=-1&tv=-1"
        guard let url = URL(string: urlString) else {
            throw QQMusicError.invalidURL
        }

        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lrc = json["lrc"] as? [String: Any],
              let lrcString = lrc["lyric"] as? String else {
            throw QQMusicError.decodeFailed
        }

        return LyricLine.parse(lrcContent: lrcString)
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("https://music.163.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        return request
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QQMusicError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw QQMusicError.requestFailed(httpResponse.statusCode)
        }
    }
}
