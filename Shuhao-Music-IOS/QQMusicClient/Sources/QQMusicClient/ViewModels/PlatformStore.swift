import Foundation
import Combine

@MainActor
final class PlatformStore: ObservableObject {
    static let shared = PlatformStore()

    @Published var selectedPlatform: MusicPlatform = .qq

    private init() {}
}
