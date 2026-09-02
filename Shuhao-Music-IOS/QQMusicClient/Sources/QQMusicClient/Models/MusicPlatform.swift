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

    /// 是否使用 songmid 作为歌曲 ID（QQ 音乐/酷狗/酷我）
    var usesSongMid: Bool {
        self == .qq || self == .kugou || self == .kuwo
    }
}
