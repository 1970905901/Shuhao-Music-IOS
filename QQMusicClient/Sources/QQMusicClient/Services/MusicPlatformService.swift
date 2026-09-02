import Foundation

/// 各音乐平台的统一服务协议
protocol MusicPlatformService: Actor {
    var platform: MusicPlatform { get }

    func search(keyword: String, page: Int, pageSize: Int) async throws -> [Song]
    func fetchPlaylists(page: Int, pageSize: Int) async throws -> [Playlist]
    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song])
    func fetchAlbumDetail(albumMid: String) async throws -> (info: AlbumInfo, songs: [Song])
    func fetchArtistDetail(singerMid: String, page: Int, pageSize: Int) async throws -> (info: ArtistInfo, songs: [Song])
    func lyric(for songMid: String) async throws -> [LyricLine]
    func fetchLeaderboards() async throws -> [Playlist]
    func fetchLeaderboardDetail(id: String) async throws -> (playlist: Playlist, songs: [Song])
}

extension MusicPlatformService {
    func fetchPlaylists(page: Int, pageSize: Int) async throws -> [Playlist] {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持歌单浏览")
    }

    func fetchPlaylistDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持歌单详情")
    }

    func fetchAlbumDetail(albumMid: String) async throws -> (info: AlbumInfo, songs: [Song]) {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持专辑详情")
    }

    func fetchArtistDetail(singerMid: String, page: Int, pageSize: Int) async throws -> (info: ArtistInfo, songs: [Song]) {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持歌手详情")
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持歌词")
    }

    func fetchLeaderboards() async throws -> [Playlist] {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持排行榜")
    }

    func fetchLeaderboardDetail(id: String) async throws -> (playlist: Playlist, songs: [Song]) {
        throw QQMusicError.custom(message: "\(platform.displayName) 暂不支持排行榜详情")
    }
}
