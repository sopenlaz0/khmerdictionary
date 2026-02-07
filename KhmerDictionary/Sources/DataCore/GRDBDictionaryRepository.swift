import Foundation
import GRDB

actor GRDBDictionaryRepository: DictionaryRepository {
    private let dbPool: DatabasePool

    init(databaseURL: URL, appliedVersionCode: Int?) throws {
        var configuration = Configuration()
        configuration.readonly = false
        configuration.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }

        dbPool = try DatabasePool(path: databaseURL.path, configuration: configuration)
        try Self.makeMigrator().migrate(dbPool)

        if let appliedVersionCode {
            try Self.setDictionaryVersionCode(dbPool: dbPool, versionCode: appliedVersionCode)
        } else if try Self.currentDictionaryVersionCode(dbPool: dbPool) == nil {
            try Self.setDictionaryVersionCode(dbPool: dbPool, versionCode: UpdateConfiguration.bundledDictionaryVersionCode)
        }
    }

    func searchWords(rawSearchTerm: String, limit: Int = 90) async throws -> [WordSummary] {
        let pattern = SearchQuery.prefixPattern(for: rawSearchTerm)
        let rows = try await dbPool.read { db in
            try RawWordSummary.fetchAll(
                db,
                sql: """
                    SELECT
                        d.id,
                        d.word,
                        d.definition,
                        EXISTS(SELECT 1 FROM bookmarks b WHERE b.word_id = d.id) AS isBookmarked
                    FROM dict d
                    WHERE d.word LIKE ? COLLATE NOCASE
                    ORDER BY d.word COLLATE NOCASE ASC
                    LIMIT ?
                """,
                arguments: [pattern, limit]
            )
        }

        return rows.map { row in
            WordSummary(
                id: row.id,
                word: row.word,
                definition: row.definition,
                previewDefinition: DefinitionFormatter.preview(from: row.definition),
                isBookmarked: row.isBookmarked
            )
        }
    }

    func getWordByID(_ wordID: Int64) async throws -> WordDetail? {
        try await dbPool.read { db in
            try RawWordSummary.fetchOne(
                db,
                sql: """
                    SELECT
                        d.id,
                        d.word,
                        d.definition,
                        EXISTS(SELECT 1 FROM bookmarks b WHERE b.word_id = d.id) AS isBookmarked
                    FROM dict d
                    WHERE d.id = ?
                    LIMIT 1
                """,
                arguments: [wordID]
            )
            .map {
                WordDetail(
                    id: $0.id,
                    word: $0.word,
                    definition: DefinitionFormatter.format($0.definition),
                    isBookmarked: $0.isBookmarked
                )
            }
        }
    }

    func listBookmarks(limit: Int = 200) async throws -> [WordSummary] {
        let rows = try await dbPool.read { db in
            try RawWordSummary.fetchAll(
                db,
                sql: """
                    SELECT
                        d.id,
                        d.word,
                        d.definition,
                        1 AS isBookmarked
                    FROM bookmarks b
                    JOIN dict d ON d.id = b.word_id
                    ORDER BY d.word COLLATE NOCASE ASC
                    LIMIT ?
                """,
                arguments: [limit]
            )
        }

        return rows.map { row in
            WordSummary(
                id: row.id,
                word: row.word,
                definition: row.definition,
                previewDefinition: DefinitionFormatter.preview(from: row.definition),
                isBookmarked: row.isBookmarked
            )
        }
    }

    func listHistory(limit: Int = 200) async throws -> [WordSummary] {
        let rows = try await dbPool.read { db in
            try RawWordSummary.fetchAll(
                db,
                sql: """
                    SELECT
                        d.id,
                        d.word,
                        d.definition,
                        EXISTS(SELECT 1 FROM bookmarks b WHERE b.word_id = d.id) AS isBookmarked
                    FROM history h
                    JOIN dict d ON d.id = h.word_id
                    ORDER BY h.viewed_at DESC
                    LIMIT ?
                """,
                arguments: [limit]
            )
        }

        return rows.map { row in
            WordSummary(
                id: row.id,
                word: row.word,
                definition: row.definition,
                previewDefinition: DefinitionFormatter.preview(from: row.definition),
                isBookmarked: row.isBookmarked
            )
        }
    }

    func setBookmark(wordID: Int64, isCurrentlyBookmarked: Bool) async throws {
        try await dbPool.write { db in
            if isCurrentlyBookmarked {
                _ = try db.execute(
                    sql: "DELETE FROM bookmarks WHERE word_id = ?",
                    arguments: [wordID]
                )
            } else {
                _ = try db.execute(
                    sql: "INSERT OR REPLACE INTO bookmarks(word_id, created_at) VALUES (?, ?)",
                    arguments: [wordID, Int(Date().timeIntervalSince1970 * 1000)]
                )
            }
        }
    }

    func addToHistory(wordID: Int64) async throws {
        try await dbPool.write { db in
            _ = try db.execute(
                sql: """
                    INSERT INTO history(word_id, viewed_at)
                    VALUES (?, ?)
                    ON CONFLICT(word_id)
                    DO UPDATE SET viewed_at = excluded.viewed_at
                """,
                arguments: [wordID, Int(Date().timeIntervalSince1970 * 1000)]
            )
        }
    }

    func currentDictionaryVersionCode() async throws -> Int? {
        try Self.currentDictionaryVersionCode(dbPool: dbPool)
    }

    func setDictionaryVersionCode(_ versionCode: Int) async throws {
        try Self.setDictionaryVersionCode(dbPool: dbPool, versionCode: versionCode)
    }

    private static func currentDictionaryVersionCode(dbPool: DatabasePool) throws -> Int? {
        try dbPool.read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: "SELECT value FROM app_meta WHERE key = ? LIMIT 1",
                arguments: ["dictionary_version_code"]
            ) else {
                return nil
            }

            guard let value: String = row["value"] else {
                return nil
            }

            return Int(value)
        }
    }

    private static func setDictionaryVersionCode(dbPool: DatabasePool, versionCode: Int) throws {
        try dbPool.write { db in
            _ = try db.execute(
                sql: """
                    INSERT INTO app_meta(key, value)
                    VALUES (?, ?)
                    ON CONFLICT(key)
                    DO UPDATE SET value = excluded.value
                """,
                arguments: ["dictionary_version_code", String(versionCode)]
            )
        }
    }

    private static func makeMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createAppTables") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS bookmarks (
                  word_id INTEGER PRIMARY KEY,
                  created_at INTEGER NOT NULL
                );

                CREATE TABLE IF NOT EXISTS history (
                  word_id INTEGER PRIMARY KEY,
                  viewed_at INTEGER NOT NULL
                );

                CREATE TABLE IF NOT EXISTS app_meta (
                  key TEXT PRIMARY KEY,
                  value TEXT NOT NULL
                );

                CREATE INDEX IF NOT EXISTS idx_history_viewed_at ON history(viewed_at DESC);
                CREATE INDEX IF NOT EXISTS idx_dict_word ON dict(word COLLATE NOCASE);
            """)
        }

        return migrator
    }
}

private struct RawWordSummary: FetchableRecord, Decodable, Sendable {
    let id: Int64
    let word: String
    let definition: String
    let isBookmarked: Bool
}
