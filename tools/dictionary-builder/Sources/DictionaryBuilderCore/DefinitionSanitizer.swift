import Foundation

public enum DefinitionSanitizer {
    private static let htmlTagRegex = try! NSRegularExpression(pattern: "<[^>]+>")
    private static let legacyAngleRegex = try! NSRegularExpression(pattern: #"<\"[^\"]+\">"#)
    private static let slashAMarkerRegex = try! NSRegularExpression(pattern: #"(?i)\s*/a\b"#)
    private static let spacesRegex = try! NSRegularExpression(pattern: #"[ \t]+"#)
    private static let blankLinesRegex = try! NSRegularExpression(pattern: #"\n{3,}"#)

    public static func sanitize(_ raw: String) -> String {
        var value = raw
        value = value.replacingOccurrences(of: "<br/>", with: "\n")
        value = value.replacingOccurrences(of: "<br>", with: "\n")
        value = replace(regex: legacyAngleRegex, in: value, with: "")
        value = replace(regex: htmlTagRegex, in: value, with: "")
        value = replace(regex: slashAMarkerRegex, in: value, with: "")
        value = value.replacingOccurrences(of: "\r\n", with: "\n")
        value = value.replacingOccurrences(of: "\r", with: "\n")
        value = replace(regex: spacesRegex, in: value, with: " ")
        value = value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "\n")
        value = replace(regex: blankLinesRegex, in: value, with: "\n\n")
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func replace(regex: NSRegularExpression, in value: String, with replacement: String) -> String {
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, options: [], range: range, withTemplate: replacement)
    }
}
