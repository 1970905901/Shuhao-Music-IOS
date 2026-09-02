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
        throw QQMusicError.custom(message: "酷我音乐歌词接口待接入")
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
