import Foundation

/// 从 LxMusic 自定义源 JS 文件中提取的可执行信息
struct ParsedLxMusicSource: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var apiURL: String
    var apiKey: String
    /// 各平台支持的音质，如 ["tx": ["128k", "320k", "flac"]]
    var qualitys: [String: [String]]
    var rawScript: String

    init(
        id: UUID = UUID(),
        name: String,
        apiURL: String,
        apiKey: String,
        qualitys: [String: [String]],
        rawScript: String
    ) {
        self.id = id
        self.name = name
        self.apiURL = apiURL
        self.apiKey = apiKey
        self.qualitys = qualitys
        self.rawScript = rawScript
    }
}

enum LxMusicSourceParserError: Error, LocalizedError {
    case missingAPIURL
    case missingAPIKey
    case missingQuality
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .missingAPIURL:
            return "未找到 API_URL 常量"
        case .missingAPIKey:
            return "未找到 API_KEY 常量"
        case .missingQuality:
            return "未找到 MUSIC_QUALITY 音质配置"
        case .invalidJSON:
            return "MUSIC_QUALITY JSON 解析失败"
        }
    }
}

/// 解析 ikun-music-source.js 这类 LxMusic 源脚本，提取调用所需常量
struct LxMusicSourceParser {
    static func parse(script: String) throws -> ParsedLxMusicSource {
        let name = extractHeaderValue(script: script, key: "name") ?? "自定义音源"

        guard let apiURL = extractStringConstant(script: script, key: "API_URL") else {
            throw LxMusicSourceParserError.missingAPIURL
        }

        guard let apiKey = extractStringConstant(script: script, key: "API_KEY") else {
            throw LxMusicSourceParserError.missingAPIKey
        }

        let qualitys = try extractQualitys(script: script)
        guard !qualitys.isEmpty else {
            throw LxMusicSourceParserError.missingQuality
        }

        return ParsedLxMusicSource(
            name: name,
            apiURL: apiURL,
            apiKey: apiKey,
            qualitys: qualitys,
            rawScript: script
        )
    }

    // MARK: - Extraction helpers

    private static func extractHeaderValue(script: String, key: String) -> String? {
        let escapedKey = NSRegularExpression.escapedPattern(for: key)
        let pattern = "@\\s*" + escapedKey + "\\s+([^\\n]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(script.startIndex..., in: script)
        guard let match = regex?.firstMatch(in: script, options: [], range: range),
              let valueRange = Range(match.range(at: 1), in: script) else {
            return nil
        }
        return script[valueRange].trimmingCharacters(in: .whitespaces)
    }

    private static func extractStringConstant(script: String, key: String) -> String? {
        let escapedKey = NSRegularExpression.escapedPattern(for: key)
        let patterns = [
            "const\\s+" + escapedKey + "\\s*=\\s*\"([^\"]+)\"",
            "const\\s+" + escapedKey + "\\s*=\\s*'([^']+)'"
        ]
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(script.startIndex..., in: script)
            if let match = regex?.firstMatch(in: script, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: script) {
                return String(script[valueRange])
            }
        }
        return nil
    }

    private static func extractQualitys(script: String) throws -> [String: [String]] {
        // 匹配 const MUSIC_QUALITY = JSON.parse('...')
        let pattern = "const\\s+MUSIC_QUALITY\\s*=\\s*JSON\\.parse\\('([^']+)'\\)"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(script.startIndex..., in: script)
        guard let match = regex.firstMatch(in: script, options: [], range: range),
              let jsonRange = Range(match.range(at: 1), in: script) else {
            return [:]
        }

        let jsonString = String(script[jsonRange])
        guard let data = jsonString.data(using: .utf8),
              let dict = try JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
            throw LxMusicSourceParserError.invalidJSON
        }
        return dict
    }
}
