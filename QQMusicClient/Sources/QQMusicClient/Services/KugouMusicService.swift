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

    func fetchPlaylists(page: Int = 1, pageSize: Int = 30) async throws -> [Playlist] {
        guard var components = URLComponents(string: "https://mobilecdn.kugou.com/api/v3/playlist/list") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pagesize", value: String(pageSize)),
            URLQueryItem(name: "sort", value: "1")
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

        return info.compactMap { item -> Playlist? in
            guard let id = item["specialid"] as? Int ?? item["specialid"] as? String,
                  let name = item["specialname"] as? String else { return nil }
            let imgUrl = item["imgurl"] as? String ?? item["img"] as? String
            return Playlist(
                id: String(id),
                name: name,
                coverURL: imgUrl.flatMap(URL.init(string:)),
                songCount: item["songcount"] as? Int,
                listenCount: item["playcount"] as? Int,
                creator: nil
            )
        }
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        guard var components = URLComponents(string: "https://mobilecdn.kugou.com/api/v3/playlist/songs") else {
            throw QQMusicError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "pid", value: id),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "pagesize", value: "100")
        ]

        guard let url = components.url else { throw QQMusicError.invalidURL }
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let songs = try parseSongList(data: data)

        let playlist = Playlist(
            id: id,
            name: "歌单",
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
                coverURL: nil
            )
        }
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
