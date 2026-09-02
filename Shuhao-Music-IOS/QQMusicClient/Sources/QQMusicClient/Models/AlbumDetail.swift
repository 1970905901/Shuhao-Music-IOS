import Foundation

struct AlbumDetail: Codable {
    let code: Int?
    let data: AlbumData?

    var albumInfo: AlbumInfo? {
        data?.albumInfo
    }

    var songs: [Song] {
        data?.songlist ?? []
    }
}

struct AlbumData: Codable {
    let albumInfo: AlbumInfo?
    let songlist: [Song]?

    enum CodingKeys: String, CodingKey {
        case albumInfo = "albumInfo"
        case songlist = "songlist"
    }
}

struct AlbumInfo: Codable, Identifiable {
    let id: String?
    let mid: String?
    let name: String?
    let singerName: String?
    let coverURL: URL?

    enum CodingKeys: String, CodingKey {
        case id = "albumID"
        case mid = "albumMID"
        case name = "albumName"
        case singerName = "singerName"
        case coverURL = "albumPic"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        mid = try container.decodeIfPresent(String.self, forKey: .mid)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        singerName = try container.decodeIfPresent(String.self, forKey: .singerName)
        if let urlString = try container.decodeIfPresent(String.self, forKey: .coverURL) {
            coverURL = URL(string: urlString)
        } else {
            coverURL = nil
        }
    }
}
