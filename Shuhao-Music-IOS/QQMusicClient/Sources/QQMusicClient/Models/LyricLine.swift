import Foundation

struct LyricLine: Identifiable, Equatable {
    let id = UUID()
    let time: TimeInterval
    let text: String

    static func parse(lrcContent: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2,3})\\](.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return lines
        }

        let nsRange = NSRange(lrcContent.startIndex..., in: lrcContent)
        let matches = regex.matches(in: lrcContent, options: [], range: nsRange)

        for match in matches {
            guard match.numberOfRanges == 5 else { continue }
            let minuteRange = Range(match.range(at: 1), in: lrcContent)
            let secondRange = Range(match.range(at: 2), in: lrcContent)
            let millisecondRange = Range(match.range(at: 3), in: lrcContent)
            let textRange = Range(match.range(at: 4), in: lrcContent)

            guard let minuteRange = minuteRange,
                  let secondRange = secondRange,
                  let millisecondRange = millisecondRange,
                  let textRange = textRange,
                  let minute = Double(lrcContent[minuteRange]),
                  let second = Double(lrcContent[secondRange]),
                  let millisRaw = Double(lrcContent[millisecondRange]) else {
                continue
            }

            let millis = millisRaw < 100 ? millisRaw / 1000.0 : millisRaw / 1000.0
            let time = minute * 60.0 + second + millis
            let text = String(lrcContent[textRange]).trimmingCharacters(in: .whitespaces)
            lines.append(LyricLine(time: time, text: text))
        }

        return lines.sorted { $0.time < $1.time }
    }
}
