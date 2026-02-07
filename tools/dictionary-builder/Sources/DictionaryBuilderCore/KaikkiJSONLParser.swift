import Foundation

public enum KaikkiJSONLParser {
    public static func parseFile(atPath path: String, metadata: SourceMetadata) throws -> [ImportCandidate] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        return try parseLines(lines, metadata: metadata)
    }

    public static func parseLines(_ lines: [String], metadata: SourceMetadata) throws -> [ImportCandidate] {
        var entries: [ImportCandidate] = []
        entries.reserveCapacity(lines.count)

        for line in lines where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let data = Data(line.utf8)
            guard let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            guard let word = raw["word"] as? String, !word.isEmpty else {
                continue
            }

            let definition = buildDefinition(from: raw)
            guard !definition.isEmpty else {
                continue
            }

            entries.append(
                ImportCandidate(
                    word: word,
                    definition: definition,
                    sourceID: metadata.sourceID,
                    license: metadata.license,
                    attribution: metadata.attribution,
                    sourceURL: metadata.sourceURL,
                    priority: metadata.priority
                )
            )
        }

        return entries
    }

    private static func buildDefinition(from raw: [String: Any]) -> String {
        guard let senses = raw["senses"] as? [[String: Any]] else {
            return ""
        }

        var glosses: [String] = []
        for sense in senses {
            if let list = sense["glosses"] as? [String] {
                glosses.append(contentsOf: list)
            } else if let rawGlosses = sense["raw_glosses"] as? [String] {
                glosses.append(contentsOf: rawGlosses)
            }
        }

        let cleaned = glosses
            .map { DefinitionSanitizer.sanitize($0) }
            .filter { !$0.isEmpty }

        return cleaned.joined(separator: "\n")
    }
}
