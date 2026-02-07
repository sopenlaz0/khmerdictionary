import Foundation

enum DefinitionFormatter {
    static func format(_ raw: String) -> String {
        var output = raw
        output = output.replacingOccurrences(of: #"<\"[^\"]+\">"#, with: "", options: .regularExpression)
        output = output.replacingOccurrences(of: "/a", with: "")
        output = output.replacingOccurrences(of: "\\n", with: "\n\n")
        output = output.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        output = output.replacingOccurrences(of: "\u{200B}", with: "")
        output = output.replacingOccurrences(of: #"[ \t]+\n"#, with: "\n", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\n[ \t]+"#, with: "\n", options: .regularExpression)
        output = output.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func preview(from raw: String, maxLength: Int = 140) -> String {
        let plain = format(raw).replacingOccurrences(of: #"\n+"#, with: " ", options: .regularExpression)
        guard plain.count > maxLength else {
            return plain
        }

        return String(plain.prefix(maxLength))
    }
}
