import Testing
@testable import DictionaryBuilderCore

struct KaikkiJSONLParserTests {
    @Test
    func parsesWordAndDefinitionFromSenses() throws {
        let lines = [
            "{" +
            "\"word\":\"កក\"," +
            "\"senses\":[{" +
            "\"glosses\":[\"first gloss\",\"second gloss\"]" +
            "}]" +
            "}"
        ]

        let metadata = SourceMetadata(
            sourceID: "kaikki-km",
            license: "CC BY-SA",
            attribution: "Wiktionary contributors",
            sourceURL: "https://kaikki.org",
            priority: 50
        )

        let entries = try KaikkiJSONLParser.parseLines(lines, metadata: metadata)
        #expect(entries.count == 1)
        #expect(entries[0].word == "កក")
        #expect(entries[0].definition == "first gloss\nsecond gloss")
        #expect(entries[0].sourceID == "kaikki-km")
    }
}
