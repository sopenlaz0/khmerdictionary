import Testing
@testable import DictionaryBuilderCore

struct MergeEngineTests {
    @Test
    func keepsHigherPrioritySourceForDuplicateWords() {
        let base = [
            ExistingDictionaryEntry(word: "កក", definition: "old def")
        ]

        let imports = [
            ImportCandidate(
                word: "កក",
                definition: "new short",
                sourceID: "source-low",
                license: "CC",
                attribution: "A",
                sourceURL: nil,
                priority: 10
            ),
            ImportCandidate(
                word: "កក",
                definition: "new better and longer definition",
                sourceID: "source-high",
                license: "CC",
                attribution: "B",
                sourceURL: "https://example.com",
                priority: 90
            )
        ]

        let result = MergeEngine.merge(baseEntries: base, importCandidates: imports)
        #expect(result.entries.count == 1)
        #expect(result.entries[0].definition == "new better and longer definition")
        #expect(result.entries[0].sourceID == "source-high")
        #expect(result.updated == 1)
    }

    @Test
    func collapsesWhitespaceAndSkipsInvalidEmptyWords() {
        let base: [ExistingDictionaryEntry] = []
        let imports = [
            ImportCandidate(
                word: "   ",
                definition: "bad",
                sourceID: "x",
                license: "CC",
                attribution: "A",
                sourceURL: nil,
                priority: 10
            ),
            ImportCandidate(
                word: " ក ក ",
                definition: "  has    spaces  ",
                sourceID: "x",
                license: "CC",
                attribution: "A",
                sourceURL: nil,
                priority: 10
            )
        ]

        let result = MergeEngine.merge(baseEntries: base, importCandidates: imports)
        #expect(result.entries.count == 1)
        #expect(result.entries[0].word == "ក ក")
        #expect(result.entries[0].definition == "has spaces")
        #expect(result.skipped == 1)
    }
}
