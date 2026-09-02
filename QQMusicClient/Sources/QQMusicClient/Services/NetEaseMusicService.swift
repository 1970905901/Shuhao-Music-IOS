import Foundation

/// 网易云音乐服务
/// 搜索/歌词使用公开 API；歌单/专辑/歌手/排行榜详情走 weapi 加密接口。
actor NetEaseMusicService: MusicPlatformService {
    static let shared = NetEaseMusicService()

    var platform: MusicPlatform { .netease }

    private let session = URLSession.shared
    private let baseURL = "https://music.163.com"

    func search(keyword: String, page: Int = 1, pageSize: Int = 20) async throws -> [Song] {
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw QQMusicError.invalidURL
        }
        let offset = (page - 1) * pageSize
        let urlString = "\(baseURL)/api/search/get/web?csrf_token=&hlpretag=&hlposttag=&s=\(encodedKeyword)&type=1&offset=\(offset)&total=true&limit=\(pageSize)"
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

        return songs.compactMap(parseSong(from:))
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        let urlString = "\(baseURL)/api/song/lyric?os=pc&id=\(songMid)&lv=-1&kv=-1&tv=-1"
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

    func fetchLeaderboards() async throws -> [Playlist] {
        Playlist.neteaseLeaderboards
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        let playlistID = id.hasPrefix("wy__") ? String(id.dropFirst(4)) : id
        let payload: [String: Any] = [
            "id": playlistID,
            "n": 100000,
            "s": 8
        ]
        let data = try await weapiRequest(endpoint: "/weapi/v3/playlist/detail", payload: payload)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["code"] as? Int == 200,
              let playlistDict = json["playlist"] as? [String: Any] else {
            throw QQMusicError.decodeFailed
        }
        let playlist = parsePlaylist(from: playlistDict, originalID: id)
        let tracks = playlistDict["tracks"] as? [[String: Any]] ?? []
        return (playlist, tracks.compactMap(parseSong(from:)))
    }

    func fetchLeaderboardDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        try await fetchPlaylistDetail(id: id)
    }

    func fetchAlbumDetail(albumMid: String) async throws -> (info: AlbumInfo, songs: [Song]) {
        let payload: [String: Any] = ["id": albumMid]
        let data = try await weapiRequest(endpoint: "/weapi/v1/album/\(albumMid)", payload: payload)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["code"] as? Int == 200,
              let albumDict = json["album"] as? [String: Any],
              let albumID = albumDict["id"] as? Int else {
            throw QQMusicError.decodeFailed
        }
        let name = albumDict["name"] as? String ?? "专辑"
        let coverURLString = albumDict["picUrl"] as? String
        let coverURL = coverURLString.flatMap { URL(string: $0) }
        let info = AlbumInfo(
            id: String(albumID),
            mid: String(albumID),
            name: name,
            singerName: nil,
            coverURL: coverURL
        )
        let songs = (json["songs"] as? [[String: Any]] ?? []).compactMap(parseSong(from:))
        return (info, songs)
    }

    func fetchArtistDetail(singerMid: String, page: Int, pageSize: Int) async throws -> (info: ArtistInfo, songs: [Song]) {
        let payload: [String: Any] = [
            "id": singerMid,
            "offset": (page - 1) * pageSize,
            "limit": pageSize,
            "total": true
        ]
        let data = try await weapiRequest(endpoint: "/weapi/v1/artist/\(singerMid)", payload: payload)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["code"] as? Int == 200,
              let artistDict = json["artist"] as? [String: Any],
              let artistID = artistDict["id"] as? Int else {
            throw QQMusicError.decodeFailed
        }
        let name = artistDict["name"] as? String ?? "歌手"
        let coverURLString = artistDict["picUrl"] as? String
        let coverURL = coverURLString.flatMap { URL(string: $0) }
        let info = ArtistInfo(
            id: String(artistID),
            mid: String(artistID),
            name: name,
            coverURL: coverURL
        )
        let songs = (json["hotSongs"] as? [[String: Any]] ?? []).compactMap(parseSong(from:))
        return (info, songs)
    }

    // MARK: - Helpers

    private func weapiRequest(endpoint: String, payload: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw QQMusicError.invalidURL
        }
        let encrypted = NetEaseWeapiCrypto.encryptedParams(for: payload)
        guard !encrypted.isEmpty,
              let params = encrypted["params"],
              let encSecKey = encrypted["encSecKey"] else {
            throw QQMusicError.custom(message: "weapi 加密失败")
        }

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "params", value: params),
            URLQueryItem(name: "encSecKey", value: encSecKey)
        ]
        guard let bodyData = bodyComponents.percentEncodedQuery?.data(using: .utf8) else {
            throw QQMusicError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://music.163.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyData
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
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

    private func parsePlaylist(from dict: [String: Any], originalID: String) -> Playlist {
        let name = dict["name"] as? String ?? "网易云歌单"
        let coverURLString = dict["coverImgUrl"] as? String
        let coverURL = coverURLString.flatMap { URL(string: $0) }
        let trackCount = dict["trackCount"] as? Int
        let playCount = dict["playCount"] as? Int
        let creatorDict = dict["creator"] as? [String: Any]
        let creator = creatorDict?["nickname"] as? String
        return Playlist(
            id: originalID,
            name: name,
            coverURL: coverURL,
            songCount: trackCount,
            listenCount: playCount,
            creator: creator
        )
    }

    private func parseSong(from item: [String: Any]) -> Song? {
        guard let id = item["id"] as? Int,
              let name = item["name"] as? String else { return nil }

        let artists = item["ar"] as? [[String: Any]] ?? (item["artists"] as? [[String: Any]]) ?? []
        let singerName = artists.compactMap { $0["name"] as? String }.joined(separator: " / ")

        let album = item["al"] as? [String: Any] ?? (item["album"] as? [String: Any])
        let albumName = album?["name"] as? String ?? ""
        let albumId = album?["id"] as? Int
        let coverURLString = album?["picUrl"] as? String

        let duration = item["dt"] as? Int ?? (item["duration"] as? Int)

        return Song(
            id: String(id),
            mid: String(id),
            name: name,
            subtitle: nil,
            album: Album(id: albumId.map(String.init), mid: nil, name: albumName),
            singers: [Singer(id: nil, mid: nil, name: singerName)],
            duration: duration.map { $0 / 1000 },
            coverURL: coverURLString.flatMap { URL(string: $0) },
            platform: .netease
        )
    }
}
