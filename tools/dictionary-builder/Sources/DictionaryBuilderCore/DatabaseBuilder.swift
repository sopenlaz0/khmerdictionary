import Foundation
import SQLite3

public enum DatabaseBuilderError: LocalizedError {
    case baseDatabaseNotFound(String)
    case sqliteOpenFailed(String)
    case sqliteExecutionFailed(String)
    case outputPathMatchesBase

    public var errorDescription: String? {
        switch self {
        case let .baseDatabaseNotFound(path):
            return "Base database not found: \(path)"
        case let .sqliteOpenFailed(path):
            return "Failed to open sqlite database: \(path)"
        case let .sqliteExecutionFailed(message):
            return "SQLite execution failed: \(message)"
        case .outputPathMatchesBase:
            return "outputDatabasePath must be different from baseDatabasePath"
        }
    }
}

public enum DatabaseBuilder {
    public static func build(config: BuildDatabaseConfig) throws -> DatabaseBuildSummary {
        let fileManager = FileManager.default
        let basePath = normalizePath(config.baseDatabasePath)
        let outputPath = normalizePath(config.outputDatabasePath)

        guard fileManager.fileExists(atPath: basePath) else {
            throw DatabaseBuilderError.baseDatabaseNotFound(basePath)
        }

        if basePath == outputPath {
            throw DatabaseBuilderError.outputPathMatchesBase
        }

        try ensureParentDirectoryExists(for: outputPath, fileManager: fileManager)
        if fileManager.fileExists(atPath: outputPath) {
            try fileManager.removeItem(atPath: outputPath)
        }

        try fileManager.copyItem(atPath: basePath, toPath: outputPath)

        var importCandidates: [ImportCandidate] = []
        for source in config.sources {
            let metadata = SourceMetadata(
                sourceID: source.id,
                license: source.license,
                attribution: source.attribution,
                sourceURL: source.sourceURL,
                priority: source.priority
            )

            let sourcePath = normalizePath(source.path)
            switch source.type {
            case .kaikkiJSONL:
                importCandidates.append(contentsOf: try KaikkiJSONLParser.parseFile(atPath: sourcePath, metadata: metadata))
            case .tsv:
                let delimiterChar = source.delimiter?.first ?? "\t"
                importCandidates.append(contentsOf: try TSVParser.parseFile(
                    atPath: sourcePath,
                    metadata: metadata,
                    delimiter: delimiterChar,
                    wordColumn: source.wordColumn ?? 0,
                    definitionColumn: source.definitionColumn ?? 1
                ))
            }
        }

        var db: OpaquePointer?
        guard sqlite3_open(outputPath, &db) == SQLITE_OK, let db else {
            throw DatabaseBuilderError.sqliteOpenFailed(outputPath)
        }
        defer { sqlite3_close(db) }

        let baseEntries = try readExistingEntries(db: db)
        let merge = MergeEngine.merge(baseEntries: baseEntries.map { ExistingDictionaryEntry(word: $0.word, definition: $0.definition) }, importCandidates: importCandidates)
        try applyMergeResult(merge, db: db)

        let totalRows = try countRows(db: db)
        return DatabaseBuildSummary(
            outputDatabasePath: outputPath,
            totalRows: totalRows,
            inserted: merge.inserted,
            updated: merge.updated,
            skipped: merge.skipped
        )
    }

    private static func readExistingEntries(db: OpaquePointer) throws -> [(id: Int64, word: String, definition: String)] {
        let sql = "SELECT id, word, definition FROM dict"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
        }
        defer { sqlite3_finalize(statement) }

        var rows: [(id: Int64, word: String, definition: String)] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            guard let wordText = sqlite3_column_text(statement, 1), let definitionText = sqlite3_column_text(statement, 2) else {
                continue
            }
            let word = String(cString: wordText)
            let definition = String(cString: definitionText)
            rows.append((id, word, definition))
        }

        return rows
    }

    private static func applyMergeResult(_ merge: MergeResult, db: OpaquePointer) throws {
        try exec(db: db, sql: "BEGIN IMMEDIATE TRANSACTION")
        do {
            var existingWordToID: [String: Int64] = [:]
            for row in try readExistingEntries(db: db) {
                existingWordToID[TextNormalization.dedupeKey(forWord: row.word)] = row.id
            }

            let updateSQL = "UPDATE dict SET word = ?, definition = ? WHERE id = ?"
            let insertSQL = "INSERT INTO dict(word, definition) VALUES (?, ?)"

            var updateStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, nil) == SQLITE_OK, let updateStmt else {
                throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
            }
            defer { sqlite3_finalize(updateStmt) }

            var insertStmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, insertSQL, -1, &insertStmt, nil) == SQLITE_OK, let insertStmt else {
                throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
            }
            defer { sqlite3_finalize(insertStmt) }

            var attributionRows: [(wordID: Int64, entry: MergedDictionaryEntry)] = []
            attributionRows.reserveCapacity(merge.entries.count)

            for entry in merge.entries {
                let key = TextNormalization.dedupeKey(forWord: entry.word)
                if let existingID = existingWordToID[key] {
                    sqlite3_reset(updateStmt)
                    sqlite3_clear_bindings(updateStmt)
                    sqlite3_bind_text(updateStmt, 1, entry.word, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(updateStmt, 2, entry.definition, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_int64(updateStmt, 3, existingID)
                    guard sqlite3_step(updateStmt) == SQLITE_DONE else {
                        throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
                    }

                    attributionRows.append((existingID, entry))
                } else {
                    sqlite3_reset(insertStmt)
                    sqlite3_clear_bindings(insertStmt)
                    sqlite3_bind_text(insertStmt, 1, entry.word, -1, SQLITE_TRANSIENT)
                    sqlite3_bind_text(insertStmt, 2, entry.definition, -1, SQLITE_TRANSIENT)
                    guard sqlite3_step(insertStmt) == SQLITE_DONE else {
                        throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
                    }

                    let newID = sqlite3_last_insert_rowid(db)
                    attributionRows.append((newID, entry))
                }
            }

            try ensureAttributionSchema(db: db)
            try replaceAttributionData(db: db, rows: attributionRows)

            try exec(db: db, sql: "CREATE INDEX IF NOT EXISTS idx_dict_word ON dict(word COLLATE NOCASE)")
            try exec(db: db, sql: "COMMIT")
        } catch {
            try? exec(db: db, sql: "ROLLBACK")
            throw error
        }
    }

    private static func ensureAttributionSchema(db: OpaquePointer) throws {
        try exec(db: db, sql: """
            CREATE TABLE IF NOT EXISTS dict_attribution (
              word_id INTEGER PRIMARY KEY,
              source_id TEXT NOT NULL,
              license TEXT NOT NULL,
              attribution TEXT NOT NULL,
              source_url TEXT,
              imported_at TEXT NOT NULL
            );
        """)
    }

    private static func replaceAttributionData(db: OpaquePointer, rows: [(wordID: Int64, entry: MergedDictionaryEntry)]) throws {
        try exec(db: db, sql: "DELETE FROM dict_attribution")

        let sql = """
            INSERT INTO dict_attribution(word_id, source_id, license, attribution, source_url, imported_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
        }
        defer { sqlite3_finalize(statement) }

        let importedAt = ISO8601DateFormatter().string(from: Date())

        for row in rows {
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)
            sqlite3_bind_int64(statement, 1, row.wordID)
            sqlite3_bind_text(statement, 2, row.entry.sourceID, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, row.entry.license, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, row.entry.attribution, -1, SQLITE_TRANSIENT)
            if let sourceURL = row.entry.sourceURL {
                sqlite3_bind_text(statement, 5, sourceURL, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            sqlite3_bind_text(statement, 6, importedAt, -1, SQLITE_TRANSIENT)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
            }
        }
    }

    private static func countRows(db: OpaquePointer) throws -> Int {
        let sql = "SELECT COUNT(*) FROM dict"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseBuilderError.sqliteExecutionFailed(sqliteError(db))
        }

        return Int(sqlite3_column_int64(statement, 0))
    }

    private static func exec(db: OpaquePointer, sql: String) throws {
        var errorPointer: UnsafeMutablePointer<Int8>?
        guard sqlite3_exec(db, sql, nil, nil, &errorPointer) == SQLITE_OK else {
            let message: String
            if let errorPointer {
                message = String(cString: errorPointer)
            } else {
                message = sqliteError(db)
            }
            sqlite3_free(errorPointer)
            throw DatabaseBuilderError.sqliteExecutionFailed(message)
        }
    }

    private static func sqliteError(_ db: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(db))
    }

    private static func ensureParentDirectoryExists(for path: String, fileManager: FileManager) throws {
        let parentURL = URL(fileURLWithPath: path).deletingLastPathComponent()
        try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)
    }

    private static func normalizePath(_ raw: String) -> String {
        (raw as NSString).expandingTildeInPath
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
