import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: String
    let mid: String
    let name: String
    let subtitle: String?
    let album: Album?
    let singers: [Singer]
    let duration: Int?
    let coverURL: URL?
    /// 歌曲所属平台：决定自定义音源的 sourceCode 与歌词/详情接口的选取
    let platform: MusicPlatform

    enum CodingKeys: String, CodingKey {
        case id = "songid"
        case mid = "songmid"
        case name = "songname"
        case subtitle = "songsubtitle"
        case album
        case singers = "singer"
        case duration = "interval"
        case platform
    }

    init(
        id: String,
        mid: String,
        name: String,
        subtitle: String?,
        album: Album?,
        singers: [Singer],
        duration: Int?,
        coverURL: URL?,
        platform: MusicPlatform
    ) {
        self.id = id
        self.mid = mid
        self.name = name
        self.subtitle = subtitle
        self.album = album
        self.singers = singers
        self.duration = duration
        self.coverURL = coverURL
        self.platform = platform
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        mid = try container.decodeIfPresent(String.self, forKey: .mid) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        album = try container.decodeIfPresent(Album.self, forKey: .album)
        singers = try container.decodeIfPresent([Singer].self, forKey: .singers) ?? []
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        coverURL = nil
        // 旧版本持久化的历史/收藏没有该字段，默认按 QQ 音乐处理
        platform = try container.decodeIfPresent(MusicPlatform.self, forKey: .platform) ?? .qq
    }

    var displayArtist: String {
        singers.map(\.name).joined(separator: " / ")
    }

    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Album: Codable, Equatable {
    let id: String?
    let mid: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id = "albumid"
        case mid = "albummid"
        case name = "albumname"
    }
}

struct Singer: Codable, Equatable {
    let id: String?
    let mid: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mid = "mid"
        case name = "name"
    }
}
