import XCTest
@testable import KhmerDictionary

final class KhmerTypographyTests: XCTestCase {
    func testDictionaryScreenTypeScale() {
        XCTAssertEqual(KhmerTypography.dictionaryHeroTitle, 30)
        XCTAssertEqual(KhmerTypography.dictionaryHeroSubtitle, 17)
        XCTAssertEqual(KhmerTypography.emptyStateTitle, 20)
        XCTAssertEqual(KhmerTypography.emptyStateBody, 15)
    }

    func testListCardTypeScale() {
        XCTAssertEqual(KhmerTypography.listWordTitle, 24)
        XCTAssertEqual(KhmerTypography.listPreviewBody, 16)
    }

    func testWordDetailTypeScale() {
        XCTAssertEqual(KhmerTypography.detailWordTitle, 36)
        XCTAssertEqual(KhmerTypography.detailBookmarkLabel, 20)
        XCTAssertEqual(KhmerTypography.detailDefinitionBody, 24)
    }
}
