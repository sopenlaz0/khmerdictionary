import Foundation
import GRDB
import XCTest
@testable import KhmerDictionary

final class DictionaryRepositoryTests: XCTestCase {
    func testPrefixPattern() {
        XCTAssertEqual(SearchQuery.prefixPattern(for: ""), "%")
        XCTAssertEqual(SearchQuery.prefixPattern(for: "ក"), "ក%")
    }

    func testRepositorySearchBookmarkAndHistoryFlow() async throws {
        let databaseURL = try makeSeededDatabase()
        let repository = try GRDBDictionaryRepository(databaseURL: databaseURL, appliedVersionCode: nil)

        let searchResults = try await repository.searchWords(rawSearchTerm: "ក", limit: 20, offset: 0)
        XCTAssertEqual(searchResults.count, 2)
        XCTAssertEqual(searchResults.map(\.word), ["កក", "កក់"])

        guard let first = searchResults.first else {
            XCTFail("Expected first search result")
            return
        }

        try await repository.setBookmark(wordID: first.id, isCurrentlyBookmarked: false)
        let bookmarks = try await repository.listBookmarks(limit: 20)
        XCTAssertEqual(bookmarks.map(\.id), [first.id])

        try await repository.addToHistory(wordID: first.id)
        try await Task.sleep(for: .milliseconds(3))
        try await repository.addToHistory(wordID: 2)

        let history = try await repository.listHistory(limit: 20)
        XCTAssertEqual(history.map(\.id), [2, first.id])

        let detail = try await repository.getWordByID(first.id)
        XCTAssertEqual(detail?.id, first.id)
        XCTAssertTrue(detail?.isBookmarked ?? false)

        let currentVersion = try await repository.currentDictionaryVersionCode()
        XCTAssertEqual(currentVersion, UpdateConfiguration.bundledDictionaryVersionCode)

        try await repository.setDictionaryVersionCode(9)
        let updatedVersion = try await repository.currentDictionaryVersionCode()
        XCTAssertEqual(updatedVersion, 9)
    }

    func testRepositorySearchSupportsPagination() async throws {
        let databaseURL = try makeSeededDatabase()
        let repository = try GRDBDictionaryRepository(databaseURL: databaseURL, appliedVersionCode: nil)

        let pageOne = try await repository.searchWords(rawSearchTerm: "", limit: 2, offset: 0)
        XCTAssertEqual(pageOne.map(\.word), ["កក", "កក់"])

        let pageTwo = try await repository.searchWords(rawSearchTerm: "", limit: 2, offset: 2)
        XCTAssertEqual(pageTwo.map(\.word), ["ខ្មែរ"])
    }

    private func makeSeededDatabase() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("db")

        let queue = try DatabaseQueue(path: url.path)
        try queue.write { db in
            try db.execute(sql: """
                CREATE TABLE dict (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    word TEXT NOT NULL,
                    definition TEXT NOT NULL
                );
            """)

            try db.execute(sql: "INSERT INTO dict (id, word, definition) VALUES (?, ?, ?)", arguments: [1, "កក", "ន័យ១/a"])
            try db.execute(sql: "INSERT INTO dict (id, word, definition) VALUES (?, ?, ?)", arguments: [2, "កក់", "ន័យ២"])
            try db.execute(sql: "INSERT INTO dict (id, word, definition) VALUES (?, ?, ?)", arguments: [3, "ខ្មែរ", "ន័យ៣"])
        }

        return url
    }
}
