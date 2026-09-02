import Foundation

actor HistoryService {
    static let shared = HistoryService()

    private let historyKey = "qqmusic.play.history"
    private let favoritesKey = "qqmusic.play.favorites"
    private let maxHistoryCount = 100

    private init() {}

    func addToHistory(song: Song) {
        var items = loadHistory()
        items.removeAll { $0.song.id == song.id }
        items.insert(HistoryItem(song: song), at: 0)
        if items.count > maxHistoryCount {
            items = Array(items.prefix(maxHistoryCount))
        }
        saveHistory(items)
    }

    func loadHistory() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return items
    }

    private func saveHistory(_ items: [HistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    func toggleFavorite(song: Song) -> Bool {
        var favorites = loadFavorites()
        if favorites.contains(where: { $0.id == song.id }) {
            favorites.removeAll { $0.id == song.id }
            saveFavorites(favorites)
            return false
        } else {
            favorites.append(song)
            saveFavorites(favorites)
            return true
        }
    }

    func isFavorite(song: Song) -> Bool {
        loadFavorites().contains(where: { $0.id == song.id })
    }

    func loadFavorites() -> [Song] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let songs = try? JSONDecoder().decode([Song].self, from: data) else {
            return []
        }
        return songs
    }

    private func saveFavorites(_ songs: [Song]) {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }
}
