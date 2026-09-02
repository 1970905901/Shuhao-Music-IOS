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

        return try parseSongList(data: data)
    }

    func fetchLeaderboards() async throws -> [Playlist] {
        Playlist.kugouLeaderboards
    }

    func fetchLeaderboardDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        let bangid = id.replacingOccurrences(of: "kg__", with: "")
        guard var components = URLComponents(string: "http://mobilecdnbj.kugou.com/api/v3/rank/song") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "version", value: "9108"),
            URLQueryItem(name: "ranktype", value: "1"),
            URLQueryItem(name: "plat", value: "0"),
            URLQueryItem(name: "pagesize", value: "100"),
            URLQueryItem(name: "area_code", value: "1"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "rankid", value: bangid),
            URLQueryItem(name: "with_res_tag", value: "0"),
            URLQueryItem(name: "show_portrait_mv", value: "1"),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["errcode"] as? Int == 0,
              let dataObj = json["data"] as? [String: Any],
              let info = dataObj["info"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        let playlist = Playlist(
            id: id,
            name: Self.leaderboardName(for: id),
            coverURL: nil,
            songCount: info.count,
            listenCount: nil,
            creator: nil
        )
        let songs = info.compactMap { item -> Song? in
            guard let hash = item["hash"] as? String, !hash.isEmpty else { return nil }
            let filename = item["filename"] as? String
            let name = (item["songname"] as? String)
                ?? filename?.components(separatedBy: " - ").last
                ?? ""
            let singer = (item["authors"] as? [[String: Any]])?
                .compactMap { $0["author_name"] as? String }
                .joined(separator: " / ")
                ?? filename?.components(separatedBy: " - ").first
                ?? ""
            let albumId = item["album_id"] as? String
            return Song(
                id: hash,
                mid: hash,
                name: name,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: item["album_name"] as? String ?? ""),
                singers: [Singer(id: nil, mid: nil, name: singer)],
                duration: item["duration"] as? Int,
                coverURL: nil,
                platform: .kugou
            )
        }
        return (playlist, songs)
    }

    func fetchPlaylists(page: Int = 1, pageSize: Int = 30) async throws -> [Playlist] {
        // mobilecdn 的 playlist/list 已返回 Access Deny，改用官网歌单广场接口
        guard var components = URLComponents(string: "http://www2.kugou.kugou.com/yueku/v9/special/getSpecial") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "is_ajax", value: "1"),
            URLQueryItem(name: "cdn", value: "cdn"),
            URLQueryItem(name: "t", value: "5"),
            URLQueryItem(name: "c", value: ""),
            URLQueryItem(name: "p", value: String(page))
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeDesktopRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let list = json["special_db"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return list.compactMap { item -> Playlist? in
            guard let specialId = item["specialid"] as? Int,
                  let name = item["specialname"] as? String,
                  !name.isEmpty else { return nil }
            return Playlist(
                id: String(specialId),
                name: name,
                coverURL: Self.coverURL(item["img"]),
                songCount: item["song_count"] as? Int,
                listenCount: Self.chineseCount(item["total_play_count"]) ?? (item["play_count"] as? Int),
                creator: item["nickname"] as? String
            )
        }
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        // 排行榜 id 形如 kg__8888，详情接口待接入，先抛明确提示
        if id.hasPrefix("kg__") {
            return try await fetchLeaderboardDetail(id: id)
        }
        // 同上，歌单详情改从官网页面内嵌的 global.data 中解析歌曲列表
        guard let url = URL(string: "http://www2.kugou.kugou.com/yueku/v9/special/single/\(id)-5-9999.html") else {
            throw QQMusicError.invalidURL
        }
        let request = makeDesktopRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let html = String(data: data, encoding: .utf8) else { throw QQMusicError.decodeFailed }
        let songs = try parseSpecialSongs(html: html)

        let playlist = Playlist(
            id: id,
            name: extractSpecialName(html: html) ?? "歌单",
            coverURL: nil,
            songCount: songs.count,
            listenCount: nil,
            creator: nil
        )
        return (playlist, songs)
    }

    func fetchAlbumDetail(albumMid: String) async throws -> (info: AlbumInfo, songs: [Song]) {
        guard var components = URLComponents(string: "https://mobilecdn.kugou.com/api/v3/album/song") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "albumid", value: albumMid),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "pagesize", value: "100")
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
        guard var components = URLComponents(string: "https://mobilecdn.kugou.com/api/v3/singer/song") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "singerid", value: singerMid),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pagesize", value: String(pageSize))
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

    private func parseSpecialSongs(html: String) throws -> [Song] {
        guard let json = capture(in: html, pattern: "global\\.data = (\\[.+\\]);"),
              let data = json.data(using: .utf8),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        return items.compactMap { item -> Song? in
            guard let hash = item["hash"] as? String, !hash.isEmpty else { return nil }
            guard let name = (item["songname"] as? String) ?? (item["fileName"] as? String) else { return nil }
            let albumId = (item["album_id"] as? Int).map(String.init) ?? (item["album_id"] as? String)
            return Song(
                id: hash,
                mid: hash,
                name: name,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: item["album_name"] as? String ?? ""),
                singers: [Singer(id: nil, mid: nil, name: item["singername"] as? String ?? "")],
                duration: item["duration"] as? Int,
                coverURL: nil,
                platform: .kugou
            )
        }
    }

    private func extractSpecialName(html: String) -> String? {
        capture(in: html, pattern: "global = \\{[\\s\\S]+?name: \"(.+?)\"[\\s\\S]+?\\};")
            ?? capture(in: html, pattern: "<h1[^>]*>(.+?)</h1>")
    }

    private func capture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    /// 官网返回 "1708.1万" / "1.2亿" 这类字符串，统一折算为整数
    private static func chineseCount(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        guard let string = value as? String, !string.isEmpty else { return nil }
        if string.hasSuffix("亿"), let number = Double(string.dropLast()) { return Int(number * 100_000_000) }
        if string.hasSuffix("万"), let number = Double(string.dropLast()) { return Int(number * 10_000) }
        return Int(string)
    }

    private static func coverURL(_ value: Any?) -> URL? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    private static func leaderboardName(for id: String) -> String {
        Playlist.kugouLeaderboards.first(where: { $0.id == id })?.name ?? "排行榜"
    }

    private func parseSongList(data: Data) throws -> [Song] {
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
            let albumId = (item["album_id"] as? Int).map(String.init) ?? (item["album_id"] as? String)
            let singerId = (item["singerid"] as? Int).map(String.init) ?? (item["singerid"] as? String)
            let duration = (item["duration"] as? Int) ?? ((item["timelength"] as? Int).map { $0 / 1000 })

            return Song(
                id: hash,
                mid: hash,
                name: songName,
                subtitle: nil,
                album: Album(id: albumId, mid: albumId, name: albumName),
                singers: [Singer(id: singerId, mid: singerId, name: singerName)],
                duration: duration,
                coverURL: nil,
                platform: .kugou
            )
        }
    }

    /// 官网 www2 页面只接受桌面 UA，移动端 UA 会返回空页面
    private func makeDesktopRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("http://www2.kugou.kugou.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        return request
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
