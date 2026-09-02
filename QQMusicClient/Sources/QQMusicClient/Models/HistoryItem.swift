import Foundation

struct HistoryItem: Identifiable, Codable, Equatable {
    let id: String
    let song: Song
    let playedAt: Date

    init(song: Song) {
        self.id = UUID().uuidString
        self.song = song
        self.playedAt = Date()
    }
}
