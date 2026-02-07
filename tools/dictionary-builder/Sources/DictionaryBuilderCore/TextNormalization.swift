import Foundation

enum TextNormalization {
    static func normalizeWord(_ raw: String) -> String {
        collapseWhitespace(raw).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizeDefinition(_ raw: String) -> String {
        collapseWhitespace(raw).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func dedupeKey(forWord word: String) -> String {
        normalizeWord(word).folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func collapseWhitespace(_ raw: String) -> String {
        raw.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}
