import Foundation

/// 酷我音乐服务
actor KuwoMusicService: MusicPlatformService {
    static let shared = KuwoMusicService()

    var platform: MusicPlatform { .kuwo }

    private let session = URLSession.shared

    func search(keyword: String, page: Int = 1, pageSize: Int = 20) async throws -> [Song] {
        guard var components = URLComponents(string: "http://search.kuwo.cn/r.s") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "all", value: keyword),
            URLQueryItem(name: "ft", value: "music"),
            URLQueryItem(name: "itemset", value: "web_2013"),
            URLQueryItem(name: "client", value: "kt"),
            URLQueryItem(name: "pn", value: String(page - 1)),
            URLQueryItem(name: "rn", value: String(pageSize)),
            URLQueryItem(name: "rformat", value: "json"),
            URLQueryItem(name: "encoding", value: "utf8")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let (data, response) = try await session.data(from: url)
        try validate(response: response)

        guard let jsonString = String(data: data, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let absList = json["abslist"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return absList.compactMap { item -> Song? in
            guard let mid = item["MUSICRID"] as? String ?? item["DC_TARGETID"] as? String,
                  let name = item["NAME"] as? String else {
                return nil
            }
            let artist = item["ARTIST"] as? String ?? ""
            let album = item["ALBUM"] as? String ?? ""
            let duration = item["DURATION"] as? Int ?? item["SONGTIME"] as? Int

            return Song(
                id: mid,
                mid: mid,
                name: name,
                subtitle: nil,
                album: Album(id: nil, mid: nil, name: album),
                singers: [Singer(id: nil, mid: nil, name: artist)],
                duration: duration,
                coverURL: nil
            )
        }
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        let musicId = songMid.replacingOccurrences(of: "MUSIC_", with: "")
        guard var components = URLComponents(string: "http://m.kuwo.cn/newh5/singles/songinfoandlrc") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "musicId", value: musicId)
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let lrclist = dataObj["lrclist"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return lrclist.compactMap { item -> LyricLine? in
            guard let timeString = item["time"] as? String,
                  let time = Double(timeString),
                  let text = item["line"] as? String else { return nil }
            return LyricLine(time: time, text: text.trimmingCharacters(in: .whitespaces))
        }.sorted { $0.time < $1.time }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("http://m.kuwo.cn", forHTTPHeaderField: "Referer")
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
