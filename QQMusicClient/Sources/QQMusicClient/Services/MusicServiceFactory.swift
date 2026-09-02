import Foundation

/// 根据平台返回对应的服务实例
enum MusicServiceFactory {
    static func service(for platform: MusicPlatform) -> any MusicPlatformService {
        switch platform {
        case .qq:
            return QQMusicAPIService.shared
        case .netease:
            return NetEaseMusicService.shared
        case .kugou:
            return KugouMusicService.shared
        case .kuwo:
            return KuwoMusicService.shared
        }
    }
}
