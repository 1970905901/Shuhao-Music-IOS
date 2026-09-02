import Foundation

struct SearchResponse: Codable {
    let code: Int?
    let data: SearchData?

    var songs: [Song] {
        data?.song?.list ?? []
    }
}

struct SearchData: Codable {
    let song: SongList?
}

struct SongList: Codable {
    let list: [Song]?
}
