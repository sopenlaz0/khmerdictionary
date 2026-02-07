import XCTest
@testable import KhmerDictionary

final class DefinitionFormatterTests: XCTestCase {
    func testRemovesLegacyTokens() {
        let raw = "<\"123\">សាកល្បង/a <b>អត្ថន័យ</b>\\nបន្ទាត់/a"
        let formatted = DefinitionFormatter.format(raw)
        XCTAssertEqual(formatted, "សាកល្បង អត្ថន័យ\n\nបន្ទាត់")
    }

    func testPreviewCollapsesLineBreaks() {
        let raw = "បន្ទាត់ទី១\\nបន្ទាត់ទី២"
        let preview = DefinitionFormatter.preview(from: raw, maxLength: 100)
        XCTAssertEqual(preview, "បន្ទាត់ទី១ បន្ទាត់ទី២")
    }
}
