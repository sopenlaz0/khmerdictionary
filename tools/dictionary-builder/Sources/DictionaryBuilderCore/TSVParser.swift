import Foundation

public enum TSVParser {
    public static func parseFile(
        atPath path: String,
        metadata: SourceMetadata,
        delimiter: Character = "\t",
        wordColumn: Int = 0,
        definitionColumn: Int = 1
    ) throws -> [ImportCandidate] {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)

        var entries: [ImportCandidate] = []
        entries.reserveCapacity(lines.count)

        for line in lines {
            let parts = line.split(separator: delimiter, omittingEmptySubsequences: false).map(String.init)
            guard parts.indices.contains(wordColumn), parts.indices.contains(definitionColumn) else {
                continue
            }

            entries.append(
                ImportCandidate(
                    word: parts[wordColumn],
                    definition: parts[definitionColumn],
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
}
