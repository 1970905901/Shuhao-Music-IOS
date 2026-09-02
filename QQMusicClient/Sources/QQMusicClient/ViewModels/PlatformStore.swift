import Foundation
import Combine

@MainActor
final class PlatformStore: ObservableObject {
    static let shared = PlatformStore()

    private static let storageKey = "qqmusic.selectedPlatform"

    @Published var selectedPlatform: MusicPlatform {
        didSet {
            UserDefaults.standard.set(selectedPlatform.rawValue, forKey: PlatformStore.storageKey)
        }
    }

    private init() {
        if let rawValue = UserDefaults.standard.string(forKey: PlatformStore.storageKey),
           let stored = MusicPlatform(rawValue: rawValue) {
            selectedPlatform = stored
        } else {
            selectedPlatform = .qq
        }
    }
}
