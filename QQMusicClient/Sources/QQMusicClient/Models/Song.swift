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

    enum CodingKeys: String, CodingKey {
        case id = "songid"
        case mid = "songmid"
        case name = "songname"
        case subtitle = "songsubtitle"
        case album
        case singers = "singer"
        case duration = "interval"
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
        coverURL = QQMusicURL.coverURL(for: mid)
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
