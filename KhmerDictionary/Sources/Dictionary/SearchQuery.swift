import Foundation

enum SearchQuery {
    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func prefixPattern(for raw: String) -> String {
        let normalized = normalize(raw)
        return normalized.isEmpty ? "%" : "\(normalized)%"
    }
}
