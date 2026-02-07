import XCTest
@testable import KhmerDictionary

final class KhmerTypographyTests: XCTestCase {
    func testDictionaryScreenTypeScale() {
        XCTAssertEqual(KhmerTypography.dictionaryHeroTitle, 24)
        XCTAssertEqual(KhmerTypography.dictionaryHeroSubtitle, 16)
        XCTAssertEqual(KhmerTypography.emptyStateTitle, 17)
        XCTAssertEqual(KhmerTypography.emptyStateBody, 15)
    }

    func testListCardTypeScale() {
        XCTAssertEqual(KhmerTypography.listWordTitle, 17)
        XCTAssertEqual(KhmerTypography.listPreviewBody, 15)
    }

    func testWordDetailTypeScale() {
        XCTAssertEqual(KhmerTypography.detailWordTitle, 28)
        XCTAssertEqual(KhmerTypography.detailBookmarkLabel, 17)
        XCTAssertEqual(KhmerTypography.detailDefinitionBody, 17)
    }
}
