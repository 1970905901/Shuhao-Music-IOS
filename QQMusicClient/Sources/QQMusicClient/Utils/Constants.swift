import Foundation

enum QQMusicURL {
    static let base = "https://u.y.qq.com/cgi-bin/musicu.fcg"
    static let searchBase = "https://c.y.qq.com/soso/fcgi-bin/client_search_cp"
    static let lyricBase = "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg"
    static let playlistBase = "https://c.y.qq.com/v8/fcg-bin/fcg_first_yqq.fcg"
    static let playlistDetailBase = "https://c.y.qq.com/qzone/fcg-bin/fcg_ucc_getcdinfo_byids_cp.fcg"
    static let albumDetailBase = "https://c.y.qq.com/v8/fcg-bin/fcg_v8_album_info_cp.fcg"
    static let artistDetailBase = "https://c.y.qq.com/v8/fcg-bin/fcg_v8_singer_track_cp.fcg"

    static func coverURL(for songMid: String) -> URL? {
        URL(string: "https://y.gtimg.cn/music/photo_new/T002R300x300M000\(songMid).jpg")
    }
}

enum QQMusicHeader {
    static let referer = "https://y.qq.com"
    static let origin = "https://y.qq.com"
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15"
}

enum QQMusicError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case decodeFailed
    case noAudioURL
    case requestFailed(Int)
    case unknown
}
