import Foundation

/// 酷狗音乐服务
actor KugouMusicService: MusicPlatformService {
    static let shared = KugouMusicService()

    var platform: MusicPlatform { .kugou }

    private let session = URLSession.shared

    func search(keyword: String, page: Int = 1, pageSize: Int = 20) async throws -> [Song] {
        guard var components = URLComponents(string: "https://mobilecdn.kugou.com/api/v3/search/song") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pagesize", value: String(pageSize)),
            URLQueryItem(name: "showtype", value: "1")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let info = dataObj["info"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return info.compactMap { item -> Song? in
            guard let hash = item["hash"] as? String,
                  let songName = item["songname"] as? String ?? item["filename"] as? String else {
                return nil
            }
            let singerName = (item["singername"] as? String) ?? ""
            let albumName = (item["album_name"] as? String) ?? ""
            let albumId = (item["album_id"] as? String) ?? ""
            let duration = (item["duration"] as? Int) ?? ((item["timelength"] as? Int).map { $0 / 1000 })
            let songId = (item["sqhash"] as? String) ?? hash

            return Song(
                id: hash,
                mid: hash,
                name: songName,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: albumName),
                singers: [Singer(id: nil, mid: nil, name: singerName)],
                duration: duration,
                coverURL: nil
            )
        }
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        guard var components = URLComponents(string: "https://wwwapi.kugou.com/yy/index.php") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "r", value: "play/getdata"),
            URLQueryItem(name: "hash", value: songMid)
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let lrcString = dataObj["lyrics"] as? String else {
            throw QQMusicError.decodeFailed
        }

        return LyricLine.parse(lrcContent: lrcString)
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("https://www.kugou.com", forHTTPHeaderField: "Referer")
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
