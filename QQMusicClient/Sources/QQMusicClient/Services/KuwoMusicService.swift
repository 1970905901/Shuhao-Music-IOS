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

    func fetchLeaderboards() async throws -> [Playlist] {
        Playlist.kuwoLeaderboards
    }

    func fetchPlaylists(page: Int = 1, pageSize: Int = 30) async throws -> [Playlist] {
        guard var components = URLComponents(string: "http://wapi.kuwo.cn/api/pc/classify/playlist/getRcmPlayList") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "loginUid", value: "0"),
            URLQueryItem(name: "loginSid", value: "0"),
            URLQueryItem(name: "appUid", value: "76039576"),
            URLQueryItem(name: "pn", value: String(max(page - 1, 0))),
            URLQueryItem(name: "rn", value: String(pageSize)),
            URLQueryItem(name: "order", value: "hot")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj = json["data"] as? [String: Any],
              let list = dataObj["data"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return list.compactMap { item -> Playlist? in
            guard let id = Self.stringValue(item["id"]),
                  let name = item["name"] as? String,
                  !name.isEmpty else { return nil }
            // 歌单详情需要按 digest 分流，这里沿用官方 id 格式 digest-{digest}__{id}
            let digest = Self.stringValue(item["digest"]) ?? "8"
            return Playlist(
                id: "digest-\(digest)__\(id)",
                name: name,
                coverURL: Self.coverURL(item["img"]),
                songCount: Self.intValue(item["total"]),
                listenCount: Self.intValue(item["listencnt"]),
                creator: item["uname"] as? String
            )
        }
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        // 排行榜 id 形如 kw__93，详情接口待接入 wbd.kuwo.cn 加密，先抛明确提示
        if id.hasPrefix("kw__") {
            return try await fetchLeaderboardDetail(id: id)
        }
        let playlistId = Self.resolvedPlaylistId(id)
        guard var components = URLComponents(string: "http://nplserver.kuwo.cn/pl.svc") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "op", value: "getlistinfo"),
            URLQueryItem(name: "pid", value: playlistId),
            URLQueryItem(name: "pn", value: "0"),
            URLQueryItem(name: "rn", value: "1000"),
            URLQueryItem(name: "encode", value: "utf8"),
            URLQueryItem(name: "keyset", value: "pl2012"),
            URLQueryItem(name: "identity", value: "kuwo"),
            URLQueryItem(name: "pcmp4", value: "1"),
            URLQueryItem(name: "vipver", value: "MUSIC_9.0.5.0_W1"),
            URLQueryItem(name: "newver", value: "1")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["result"] as? String == "ok" else {
            throw QQMusicError.decodeFailed
        }

        let songs = (json["musiclist"] as? [[String: Any]])?.compactMap { item -> Song? in
            guard let musicId = Self.stringValue(item["id"]),
                  let name = item["name"] as? String else { return nil }
            let albumId = Self.stringValue(item["albumid"])
            let artistId = Self.stringValue(item["artistid"])
            return Song(
                id: musicId,
                mid: musicId,
                name: name,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: item["album"] as? String ?? ""),
                singers: [Singer(id: artistId, mid: artistId, name: item["artist"] as? String ?? "")],
                duration: Self.intValue(item["duration"]),
                coverURL: Self.coverURL((item["albumpic"] as? String)?.replacingOccurrences(of: "/120/", with: "/500/")),
                platform: .kuwo
            )
        } ?? []

        let playlist = Playlist(
            id: id,
            name: (json["title"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "歌单",
            coverURL: Self.coverURL(json["pic"]),
            songCount: songs.count,
            listenCount: Self.intValue(json["playnum"]),
            creator: json["uname"] as? String
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
            guard let rawMid = item["MUSICRID"] as? String ?? item["DC_TARGETID"] as? String,
                  let name = item["NAME"] as? String else {
                return nil
            }
            // MUSICRID 形如 MUSIC_123456，自定义音源与歌词接口都按纯数字 id 处理
            let mid = rawMid.replacingOccurrences(of: "MUSIC_", with: "")
            let artist = item["ARTIST"] as? String ?? ""
            let album = item["ALBUM"] as? String ?? ""
            let albumId = item["ALBUMID"] as? String
            let artistId = item["ARTISTID"] as? String

            return Song(
                id: mid,
                mid: mid,
                name: name,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: album),
                singers: [Singer(id: artistId, mid: artistId, name: artist)],
                duration: Self.intValue(item["DURATION"]) ?? Self.intValue(item["SONGTIME"]),
                coverURL: nil,
                platform: .kuwo
            )
        }
    }

    // MARK: - Value Helpers

    /// 列表返回的 id 形如 digest-8__2432653113，详情接口只接受后半段纯数字
    private static func resolvedPlaylistId(_ raw: String) -> String {
        guard raw.hasPrefix("digest-"), let range = raw.range(of: "__") else { return raw }
        let id = String(raw[range.upperBound...])
        return id.isEmpty ? raw : id
    }

    private static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String, !string.isEmpty { return string }
        if let int = value as? Int { return String(int) }
        return nil
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let string = value as? String { return Int(string) }
        if let double = value as? Double { return Int(double) }
        return nil
    }

    private static func coverURL(_ value: Any?) -> URL? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return URL(string: string)
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
