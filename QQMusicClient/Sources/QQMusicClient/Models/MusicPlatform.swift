import Foundation

enum MusicPlatform: String, CaseIterable, Identifiable, Codable, Equatable {
    case qq = "tx"
    case netease = "wy"
    case kugou = "kg"
    case kuwo = "kw"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qq: return "QQ 音乐"
        case .netease: return "网易云音乐"
        case .kugou: return "酷狗音乐"
        case .kuwo: return "酷我音乐"
        }
    }

    var sourceCode: String {
        rawValue
    }

    /// 该平台当前已接入的能力，未声明的能力一律走 UI 降级而不是发起必然失败的请求
    var capabilities: Set<PlatformCapability> {
        switch self {
        case .qq, .kugou:
            return Set(PlatformCapability.allCases)
        case .kuwo:
            return [.search, .playlist, .playlistDetail, .album, .artist, .lyric, .leaderboard]
        case .netease:
            return [.search, .lyric, .leaderboard, .playlistDetail, .album, .artist]
        }
    }

    func supports(_ capability: PlatformCapability) -> Bool {
        capabilities.contains(capability)
    }

    /// 能力缺失时的统一提示文案
    func unsupportedMessage(_ capability: PlatformCapability) -> String {
        "\(displayName) 暂不支持\(capability.displayName)，请切换到其它平台"
    }
}

/// 各平台能力，用于入口显隐与空态提示
enum PlatformCapability: String, CaseIterable, Identifiable {
    case search
    case playlist
    case playlistDetail
    case album
    case artist
    case lyric
    case leaderboard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .search: return "搜索"
        case .playlist: return "歌单广场"
        case .playlistDetail: return "歌单详情"
        case .album: return "专辑详情"
        case .artist: return "歌手详情"
        case .lyric: return "歌词"
        case .leaderboard: return "排行榜"
        }
    }
}
