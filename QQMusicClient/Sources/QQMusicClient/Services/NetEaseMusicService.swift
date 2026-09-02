import Foundation

/// 网易云音乐服务
/// 说明：网易云官方搜索接口需要 weapi 加密，本实现预留架构，搜索/歌词等可替换为可用端点。
actor NetEaseMusicService: MusicPlatformService {
    static let shared = NetEaseMusicService()

    var platform: MusicPlatform { .netease }

    private let session = URLSession.shared

    func search(keyword: String, page: Int = 1, pageSize: Int = 20) async throws -> [Song] {
        // TODO: 替换为实际可用的网易云搜索端点（需处理 weapi 加密）
        throw QQMusicError.custom(message: "网易云音乐搜索接口待接入（需 weapi 加密）")
    }

    func lyric(for songMid: String) async throws -> [LyricLine] {
        throw QQMusicError.custom(message: "网易云音乐歌词接口待接入")
    }
}
