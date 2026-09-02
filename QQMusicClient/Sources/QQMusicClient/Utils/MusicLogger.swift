import Foundation
import os.log

/// 统一日志封装：开发/调试阶段使用 os_log，便于后续接入远程日志或崩溃上报
enum MusicLogger {
    private static let logger = Logger(subsystem: "com.shuhao.QQMusicClient", category: "music")

    static func audioSessionError(_ error: Error) {
        logger.error("Audio session configuration failed: \(error.localizedDescription, privacy: .public)")
    }
}
