import XCTest
@testable import KhmerDictionary

final class SearchPlacementPolicyTests: XCTestCase {
    func testDictionarySearchPrefersNavigationBarDrawerAlways() {
        XCTAssertTrue(DictionarySearchPlacementPolicy.prefersNavigationBarDrawerAlways)
    }

    func testDictionarySearchUsesAdaptiveSystemPlacement() {
        XCTAssertFalse(DictionarySearchPlacementPolicy.usesAdaptiveSystemPlacement)
    }

    func testDictionarySearchUsesBottomMinimizedToolbar() {
        XCTAssertFalse(DictionarySearchPlacementPolicy.usesBottomMinimizedSearchToolbar)
    }
}
