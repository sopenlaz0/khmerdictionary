import Testing
@testable import DictionaryBuilderCore

struct DefinitionSanitizerTests {
    @Test
    func removesLegacyMarkersAndHtmlTags() {
        let raw = "<i>និយម</i> /a <\"legacy\"> line1<br/>line2"
        let cleaned = DefinitionSanitizer.sanitize(raw)

        #expect(cleaned == "និយម line1\nline2")
    }

    @Test
    func normalizesRepeatedBlankLines() {
        let raw = "a\n\n\n\n b"
        let cleaned = DefinitionSanitizer.sanitize(raw)
        #expect(cleaned == "a\n\nb")
    }
}
