import Foundation

actor QQMusicAPIService: MusicPlatformService {
    static let shared = QQMusicAPIService()

    var platform: MusicPlatform { .qq }

    private let session = URLSession.shared
    private let guid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16).description
    private var cookie: String?

    private let searchCache = RequestCache<String, [Song]>()
    private let playlistListCache = RequestCache<String, [Playlist]>()
    private let playlistDetailCache = RequestCache<String, (playlist: Playlist, songs: [Song])>()
    private let albumDetailCache = RequestCache<String, (info: AlbumInfo, songs: [Song])>()
    private let artistDetailCache = RequestCache<String, (info: ArtistInfo, songs: [Song])>()
    private let lyricCache = RequestCache<String, [LyricLine]>()

    func updateCookie(_ cookie: String) {
        self.cookie = cookie
    }

    func search(keyword: String, page: Int = 1, pageSize: Int = 20) async throws -> [Song] {
        let cacheKey = "search:\(keyword):\(page):\(pageSize)"
        if let cached = await searchCache.value(for: cacheKey) {
            return cached
        }

        guard var components = URLComponents(string: QQMusicURL.searchBase) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "p", value: String(page)),
            URLQueryItem(name: "n", value: String(pageSize)),
            URLQueryItem(name: "w", value: keyword),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "cr", value: "1"),
            URLQueryItem(name: "g_tk", value: gTk),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url)

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        let songs = decoded.songs
        await searchCache.setValue(songs, for: cacheKey)
        return songs
    }

    func audioURL(for songMid: String) async throws -> URL {
        let payload: [String: Any] = [
            "req": [
                "module": "CDN.SrfCdnDispatchServer",
                "method": "GetCdnDispatch",
                "param": [
                    "guid": guid,
                    "calltype": 0,
                    "userip": ""
                ]
            ],
            "req_0": [
                "module": "vkey.GetVkeyServer",
                "method": "CgiGetVkey",
                "param": [
                    "guid": guid,
                    "songmid": [songMid],
                    "songtype": [0],
                    "uin": "0",
                    "loginflag": 1,
                    "platform": "20"
                ]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw QQMusicError.invalidURL
        }

        guard var components = URLComponents(string: QQMusicURL.base) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "data", value: String(data: jsonData, encoding: .utf8))
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let req0 = json["req_0"] as? [String: Any],
              let dataObj = req0["data"] as? [String: Any],
              let midURLInfo = dataObj["midurlinfo"] as? [[String: Any]],
              let first = midURLInfo.first,
              let purl = first["purl"] as? String,
              !purl.isEmpty,
              let sip = (dataObj["sip"] as? [String])?.first else {
            throw QQMusicError.noAudioURL
        }

        guard let url = URL(string: sip + purl) else { throw QQMusicError.invalidURL }
        return url
    }

    func fetchPlaylists(page: Int = 1, pageSize: Int = 30) async throws -> [Playlist] {
        let cacheKey = "playlists:\(page):\(pageSize)"
        if let cached = await playlistListCache.value(for: cacheKey) {
            return cached
        }

        guard var components = URLComponents(string: QQMusicURL.playlistBase) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "tpl", value: "v12"),
            URLQueryItem(name: "page", value: "other"),
            URLQueryItem(name: "platform", value: "h5"),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url)

        let decoded = try JSONDecoder().decode(PlaylistListResponse.self, from: data)
        let playlists = decoded.playlists
        await playlistListCache.setValue(playlists, for: cacheKey)
        return playlists
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        // 榜单 id 形如 tx__4，与歌单详情接口不同，分派到排行榜详情
        if id.hasPrefix("tx__") {
            return try await fetchLeaderboardDetail(id: id)
        }

        let cacheKey = "playlist:\(id)"
        if let cached = await playlistDetailCache.value(for: cacheKey) {
            return cached
        }

        guard var components = URLComponents(string: QQMusicURL.playlistDetailBase) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "type", value: "1"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "utf8", value: "1"),
            URLQueryItem(name: "onlysong", value: "0"),
            URLQueryItem(name: "disstid", value: id),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "g_tk", value: gTk),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url)

        let decoded = try JSONDecoder().decode(PlaylistDetailResponse.self, from: data)
        guard let playlist = decoded.playlist else {
            throw QQMusicError.decodeFailed
        }
        let result = (playlist, decoded.songs)
        await playlistDetailCache.setValue(result, for: cacheKey)
        return result
    }

    // MARK: - 排行榜

    func fetchLeaderboards() async throws -> [Playlist] {
        // 参考 tx/leaderboard.js，榜单列表硬编码，避免依赖已失效的 topList 接口
        return [
            Playlist(id: "tx__4", name: "流行指数榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__26", name: "热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__27", name: "新歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__62", name: "飙升榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__58", name: "说唱榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__57", name: "喜力电音榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__28", name: "网络歌曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__5", name: "内地榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__3", name: "欧美榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__59", name: "香港地区榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__16", name: "韩国榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__60", name: "抖快榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__29", name: "影视金曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__17", name: "日本榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__52", name: "腾讯音乐人原创榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__36", name: "K歌金曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__61", name: "台湾地区榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__63", name: "DJ舞曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__64", name: "综艺新歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__65", name: "国风热歌榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__67", name: "听歌识曲榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__72", name: "动漫音乐榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__73", name: "游戏音乐榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__75", name: "有声榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
            Playlist(id: "tx__131", name: "校园音乐人排行榜", coverURL: nil, songCount: nil, listenCount: nil, creator: nil),
        ]
    }

    func fetchLeaderboardDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        let cacheKey = "leaderboard:\(id)"
        if let cached = await playlistDetailCache.value(for: cacheKey) {
            return cached
        }

        let bangid = id.replacingOccurrences(of: "tx__", with: "")
        guard var components = URLComponents(string: "https://c.y.qq.com/v8/fcg-bin/fcg_v8_toplist_cp.fcg") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "tpl", value: "3"),
            URLQueryItem(name: "page", value: "detail"),
            URLQueryItem(name: "date", value: ""),
            URLQueryItem(name: "topid", value: bangid),
            URLQueryItem(name: "type", value: "top"),
            URLQueryItem(name: "song_begin", value: "0"),
            URLQueryItem(name: "song_num", value: "300"),
            URLQueryItem(name: "g_tk", value: "5381"),
            URLQueryItem(name: "loginUin", value: "0"),
            URLQueryItem(name: "hostUin", value: "0"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "inCharset", value: "utf8"),
            URLQueryItem(name: "outCharset", value: "utf-8"),
            URLQueryItem(name: "notice", value: "0"),
            URLQueryItem(name: "platform", value: "yqq.json"),
            URLQueryItem(name: "needNewCode", value: "0"),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("https://y.qq.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["code"] as? Int == 0,
              let songlist = json["songlist"] as? [[String: Any]] else {
            throw QQMusicError.decodeFailed
        }

        let playlist = Playlist(id: id, name: leaderboardName(for: id), coverURL: nil, songCount: songlist.count, listenCount: nil, creator: nil)
        let songs = songlist.compactMap { item -> Song? in
            guard let dataObj = item["data"] as? [String: Any],
                  let mid = dataObj["songmid"] as? String, !mid.isEmpty,
                  let name = dataObj["songname"] as? String else { return nil }
            let singers = (dataObj["singer"] as? [[String: Any]])?.compactMap { singer -> Singer? in
                guard let sname = singer["name"] as? String else { return nil }
                return Singer(id: (singer["id"] as? Int).map(String.init), mid: singer["mid"] as? String, name: sname)
            } ?? []
            let albumMid = dataObj["albummid"] as? String
            let albumName = dataObj["albumname"] as? String ?? ""
            return Song(
                id: mid,
                mid: mid,
                name: name,
                subtitle: nil,
                album: Album(id: albumMid, mid: albumMid, name: albumName),
                singers: singers,
                duration: dataObj["interval"] as? Int,
                coverURL: nil,
                platform: .qq
            )
        }
        let result = (playlist, songs)
        await playlistDetailCache.setValue(result, for: cacheKey)
        return result
    }

    private func leaderboardName(for id: String) -> String {
        let map: [String: String] = [
            "tx__4": "流行指数榜",
            "tx__26": "热歌榜",
            "tx__27": "新歌榜",
            "tx__62": "飙升榜",
            "tx__58": "说唱榜",
            "tx__57": "喜力电音榜",
            "tx__28": "网络歌曲榜",
            "tx__5": "内地榜",
            "tx__3": "欧美榜",
            "tx__59": "香港地区榜",
            "tx__16": "韩国榜",
            "tx__60": "抖快榜",
            "tx__29": "影视金曲榜",
            "tx__17": "日本榜",
            "tx__52": "腾讯音乐人原创榜",
            "tx__36": "K歌金曲榜",
            "tx__61": "台湾地区榜",
            "tx__63": "DJ舞曲榜",
            "tx__64": "综艺新歌榜",
            "tx__65": "国风热歌榜",
            "tx__67": "听歌识曲榜",
            "tx__72": "动漫音乐榜",
            "tx__73": "游戏音乐榜",
            "tx__75": "有声榜",
            "tx__131": "校园音乐人排行榜",
        ]
        return map[id] ?? "排行榜"
    }

    func fetchAlbumDetail(albumMid: String) async throws -> (info: AlbumInfo, songs: [Song]) {
        let cacheKey = "album:\(albumMid)"
        if let cached = await albumDetailCache.value(for: cacheKey) {
            return cached
        }

        guard var components = URLComponents(string: QQMusicURL.albumDetailBase) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "albummid", value: albumMid),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "g_tk", value: gTk),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url)

        let decoded = try JSONDecoder().decode(AlbumDetail.self, from: data)
        guard let info = decoded.albumInfo else {
            throw QQMusicError.decodeFailed
        }
        let result = (info, decoded.songs)
        await albumDetailCache.setValue(result, for: cacheKey)
        return result
    }

    func fetchArtistDetail(singerMid: String, page: Int = 1, pageSize: Int = 30) async throws -> (info: ArtistInfo, songs: [Song]) {
        let cacheKey = "artist:\(singerMid):\(page):\(pageSize)"
        if let cached = await artistDetailCache.value(for: cacheKey) {
            return cached
        }

        guard var components = URLComponents(string: QQMusicURL.artistDetailBase) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "singermid", value: singerMid),
            URLQueryItem(name: "order", value: "listen"),
            URLQueryItem(name: "begin", value: String((page - 1) * pageSize)),
            URLQueryItem(name: "num", value: String(pageSize)),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "g_tk", value: gTk),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url)

        let decoded = try JSONDecoder().decode(ArtistDetail.self, from: data)
        guard let info = decoded.artistInfo else {
            throw QQMusicError.decodeFailed
        }
        let result = (info, decoded.songs)
        await artistDetailCache.setValue(result, for: cacheKey)
        return result
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        let cacheKey = "lyric:\(songMid)"
        if let cached = await lyricCache.value(for: cacheKey) {
            return cached
        }

        guard var components = URLComponents(string: QQMusicURL.lyricBase) else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "songmid", value: songMid),
            URLQueryItem(name: "pcachetime", value: String(Date().timeIntervalSince1970)),
            URLQueryItem(name: "g_tk", value: gTk),
            URLQueryItem(name: "format", value: "json"),
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let data = try await requestData(url: url) { request in
            request.setValue("https://y.qq.com/portal/player.html", forHTTPHeaderField: "Referer")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lyricBase64 = json["lyric"] as? String,
              let lyricData = Data(base64Encoded: lyricBase64),
              let lyricString = String(data: lyricData, encoding: .utf8) else {
            throw QQMusicError.decodeFailed
        }

        let lyrics = LyricLine.parse(lrcContent: lyricString)
        await lyricCache.setValue(lyrics, for: cacheKey)
        return lyrics
    }

    private var gTk: String {
        guard let cookie = cookie,
              let skey = extractSKey(from: cookie) else {
            return "5381"
        }
        return String(computeGTK(from: skey))
    }

    private func extractSKey(from cookie: String) -> String? {
        let tokens = cookie.split(separator: ";")
        for token in tokens {
            let pair = token.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else { continue }
            let key = pair[0].trimmingCharacters(in: .whitespaces)
            if key == "p_skey" || key == "skey" {
                return String(pair[1])
            }
        }
        return nil
    }

    private func computeGTK(from skey: String) -> Int {
        var hash = 5381
        for char in skey {
            hash += (hash << 5) + Int(char.unicodeScalars.first?.value ?? 0)
        }
        return hash & 0x7fffffff
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(QQMusicHeader.referer, forHTTPHeaderField: "Referer")
        request.setValue(QQMusicHeader.origin, forHTTPHeaderField: "Origin")
        request.setValue(QQMusicHeader.userAgent, forHTTPHeaderField: "User-Agent")
        if let cookie = cookie {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }
        request.timeoutInterval = 30
        return request
    }

    private func requestData(url: URL, configure: ((inout URLRequest) -> Void)? = nil) async throws -> Data {
        var lastError: Error?
        for attempt in 0..<2 {
            do {
                var request = makeRequest(url: url)
                configure?(&request)
                let (data, response) = try await session.data(for: request)
                try validate(response: response)
                return data
            } catch {
                lastError = error
                if attempt == 0, let error = error as? QQMusicError,
                   case .requestFailed = error {
                    continue
                }
                throw error
            }
        }
        throw lastError ?? QQMusicError.unknown
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
