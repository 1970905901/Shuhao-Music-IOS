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
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        return try parseSongList(data: data)
    }

    func fetchPlaylists(page: Int = 1, pageSize: Int = 30) async throws -> [Playlist] {
        // 酷我公开接口暂无稳定的歌单广场入口，返回空列表避免崩溃
        return []
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        guard var components = URLComponents(string: "http://nplserver.kuwo.cn/pl.svc") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "op", value: "getlistinfo"),
            URLQueryItem(name: "pid", value: id),
            URLQueryItem(name: "pn", value: "0"),
            URLQueryItem(name: "rn", value: "100"),
            URLQueryItem(name: "encode", value: "utf-8"),
            URLQueryItem(name: "keyset", value: "kuwo2014"),
            URLQueryItem(name: "identity", value: "kuwo2014")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try parseJSONPOrJSON(data: data),
              let title = json["title"] as? String else {
            throw QQMusicError.decodeFailed
        }

        let songs = (json["musiclist"] as? [[String: Any]])?.compactMap { item -> Song? in
            guard let rid = item["rid"] as? Int,
                  let name = item["name"] as? String else { return nil }
            let artist = item["artist"] as? String ?? ""
            let album = item["album"] as? String ?? ""
            let duration = item["duration"] as? Int
            return Song(
                id: "MUSIC_\(rid)",
                mid: "MUSIC_\(rid)",
                name: name,
                subtitle: nil,
                album: Album(id: nil, mid: nil, name: album),
                singers: [Singer(id: nil, mid: nil, name: artist)],
                duration: duration,
                coverURL: nil,
                platform: .kuwo
            )
        } ?? []

        let playlist = Playlist(
            id: id,
            name: title,
            coverURL: nil,
            songCount: songs.count,
            listenCount: nil,
            creator: nil
        )
        return (playlist, songs)
    }

    func fetchAlbumDetail(albumMid: String) async throws -> (info: AlbumInfo, songs: [Song]) {
        guard var components = URLComponents(string: "http://search.kuwo.cn/r.s") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "ft", value: "music"),
            URLQueryItem(name: "albumid", value: albumMid),
            URLQueryItem(name: "pn", value: "0"),
            URLQueryItem(name: "rn", value: "100"),
            URLQueryItem(name: "rformat", value: "json"),
            URLQueryItem(name: "encoding", value: "utf8")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let songs = try parseSongList(data: data)
        let albumName = songs.first?.album?.name ?? ""
        let info = AlbumInfo(
            id: albumMid,
            mid: albumMid,
            name: albumName,
            singerName: songs.first?.singers.first?.name ?? "",
            coverURL: nil
        )
        return (info, songs)
    }

    func fetchArtistDetail(singerMid: String, page: Int = 1, pageSize: Int = 30) async throws -> (info: ArtistInfo, songs: [Song]) {
        guard var components = URLComponents(string: "http://search.kuwo.cn/r.s") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "ft", value: "music"),
            URLQueryItem(name: "artistid", value: singerMid),
            URLQueryItem(name: "pn", value: String(page - 1)),
            URLQueryItem(name: "rn", value: String(pageSize)),
            URLQueryItem(name: "rformat", value: "json"),
            URLQueryItem(name: "encoding", value: "utf8")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let songs = try parseSongList(data: data)
        let info = ArtistInfo(
            id: singerMid,
            mid: singerMid,
            name: songs.first?.singers.first?.name ?? "",
            coverURL: nil
        )
        return (info, songs)
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

    private func parseSongList(data: Data) throws -> [Song] {
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
            let albumId = item["ALBUMID"] as? String
            let artistId = item["ARTISTID"] as? String
            let duration = item["DURATION"] as? Int ?? item["SONGTIME"] as? Int

            return Song(
                id: mid,
                mid: mid,
                name: name,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: album),
                singers: [Singer(id: artistId, mid: artistId, name: artist)],
                duration: duration,
                coverURL: nil,
                platform: .kuwo
            )
        }
    }

    private func parseJSONPOrJSON(data: Data) throws -> [String: Any]? {
        guard let raw = String(data: data, encoding: .utf8) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if let jsonData = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return json
        }
        return nil
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
