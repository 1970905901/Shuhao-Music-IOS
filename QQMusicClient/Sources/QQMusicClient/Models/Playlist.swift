import Foundation

struct Playlist: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let coverURL: URL?
    let songCount: Int?
    let listenCount: Int?
    let creator: String?

    enum CodingKeys: String, CodingKey {
        case id = "dissid"
        case name = "dissname"
        case coverURL = "imgurl"
        case songCount = "song_count"
        case listenCount = "listennum"
        case creator = "creator"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        if let urlString = try container.decodeIfPresent(String.self, forKey: .coverURL) {
            coverURL = URL(string: urlString)
        } else {
            coverURL = nil
        }
        songCount = try container.decodeIfPresent(Int.self, forKey: .songCount)
        listenCount = try container.decodeIfPresent(Int.self, forKey: .listenCount)
        creator = try container.decodeIfPresent(String.self, forKey: .creator)
    }

    init(id: String, name: String, coverURL: URL?, songCount: Int?, listenCount: Int?, creator: String?) {
        self.id = id
        self.name = name
        self.coverURL = coverURL
        self.songCount = songCount
        self.listenCount = listenCount
        self.creator = creator
    }
}

struct PlaylistListResponse: Codable {
    let code: Int?
    let data: PlaylistListData?

    var playlists: [Playlist] {
        data?.list ?? []
    }
}

struct PlaylistListData: Codable {
    let list: [Playlist]?
}

struct PlaylistDetailResponse: Codable {
    let code: Int?
    let cdlist: [PlaylistDetail]?

    var songs: [Song] {
        cdlist?.first?.songlist ?? []
    }

    var playlist: Playlist? {
        cdlist?.first.flatMap {
            Playlist(
                id: $0.dissid ?? "",
                name: $0.dissname ?? "",
                coverURL: URL(string: $0.imgurl ?? ""),
                songCount: $0.songCount,
                listenCount: $0.listennum,
                creator: nil
            )
        }
    }
}

struct PlaylistDetail: Codable {
    let dissid: String?
    let dissname: String?
    let imgurl: String?
    let songCount: Int?
    let listennum: Int?
    let songlist: [Song]?

    enum CodingKeys: String, CodingKey {
        case dissid
        case dissname
        case imgurl
        case songCount = "song_count"
        case listennum
        case songlist
    }
}
