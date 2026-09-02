import Foundation

struct ArtistDetail: Codable {
    let code: Int?
    let data: ArtistData?

    var artistInfo: ArtistInfo? {
        data?.singerInfo
    }

    var songs: [Song] {
        data?.songlist ?? []
    }
}

struct ArtistData: Codable {
    let singerInfo: ArtistInfo?
    let songlist: [Song]?

    enum CodingKeys: String, CodingKey {
        case singerInfo = "singer_info"
        case songlist = "songlist"
    }
}

struct ArtistInfo: Codable, Identifiable {
    let id: String?
    let mid: String?
    let name: String?
    let coverURL: URL?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mid = "mid"
        case name = "name"
        case coverURL = "pic"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        mid = try container.decodeIfPresent(String.self, forKey: .mid)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        if let urlString = try container.decodeIfPresent(String.self, forKey: .coverURL) {
            coverURL = URL(string: urlString)
        } else {
            coverURL = nil
        }
    }
}
