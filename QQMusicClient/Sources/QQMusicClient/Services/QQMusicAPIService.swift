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
