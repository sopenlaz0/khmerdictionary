import Foundation

public struct ExistingDictionaryEntry: Equatable, Sendable {
    public let word: String
    public let definition: String

    public init(word: String, definition: String) {
        self.word = word
        self.definition = definition
    }
}

public struct ImportCandidate: Equatable, Sendable {
    public let word: String
    public let definition: String
    public let sourceID: String
    public let license: String
    public let attribution: String
    public let sourceURL: String?
    public let priority: Int

    public init(
        word: String,
        definition: String,
        sourceID: String,
        license: String,
        attribution: String,
        sourceURL: String?,
        priority: Int
    ) {
        self.word = word
        self.definition = definition
        self.sourceID = sourceID
        self.license = license
        self.attribution = attribution
        self.sourceURL = sourceURL
        self.priority = priority
    }
}

public struct SourceMetadata: Equatable, Sendable {
    public let sourceID: String
    public let license: String
    public let attribution: String
    public let sourceURL: String?
    public let priority: Int

    public init(sourceID: String, license: String, attribution: String, sourceURL: String?, priority: Int) {
        self.sourceID = sourceID
        self.license = license
        self.attribution = attribution
        self.sourceURL = sourceURL
        self.priority = priority
    }
}

public struct MergedDictionaryEntry: Equatable, Sendable {
    public let word: String
    public let definition: String
    public let sourceID: String
    public let license: String
    public let attribution: String
    public let sourceURL: String?
    public let priority: Int

    public init(
        word: String,
        definition: String,
        sourceID: String,
        license: String,
        attribution: String,
        sourceURL: String?,
        priority: Int
    ) {
        self.word = word
        self.definition = definition
        self.sourceID = sourceID
        self.license = license
        self.attribution = attribution
        self.sourceURL = sourceURL
        self.priority = priority
    }
}

public struct MergeResult: Equatable, Sendable {
    public let entries: [MergedDictionaryEntry]
    public let inserted: Int
    public let updated: Int
    public let skipped: Int

    public init(entries: [MergedDictionaryEntry], inserted: Int, updated: Int, skipped: Int) {
        self.entries = entries
        self.inserted = inserted
        self.updated = updated
        self.skipped = skipped
    }
}

public struct DatabaseUpdateManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let release: Release
    public let database: Database

    public init(schemaVersion: Int, release: Release, database: Database) {
        self.schemaVersion = schemaVersion
        self.release = release
        self.database = database
    }

    public struct Release: Codable, Equatable, Sendable {
        public let versionCode: Int
        public let versionName: String
        public let publishedAt: String

        public init(versionCode: Int, versionName: String, publishedAt: String) {
            self.versionCode = versionCode
            self.versionName = versionName
            self.publishedAt = publishedAt
        }
    }

    public struct Database: Codable, Equatable, Sendable {
        public let url: String
        public let sha256: String
        public let sizeBytes: Int
        public let signatureHex: String

        public init(url: String, sha256: String, sizeBytes: Int, signatureHex: String) {
            self.url = url
            self.sha256 = sha256
            self.sizeBytes = sizeBytes
            self.signatureHex = signatureHex
        }
    }
}

public struct BuildDatabaseConfig: Codable, Equatable, Sendable {
    public let baseDatabasePath: String
    public let outputDatabasePath: String
    public let sources: [ImportSourceConfig]

    public init(baseDatabasePath: String, outputDatabasePath: String, sources: [ImportSourceConfig]) {
        self.baseDatabasePath = baseDatabasePath
        self.outputDatabasePath = outputDatabasePath
        self.sources = sources
    }
}

public struct ImportSourceConfig: Codable, Equatable, Sendable {
    public let id: String
    public let type: SourceType
    public let path: String
    public let license: String
    public let attribution: String
    public let sourceURL: String?
    public let priority: Int
    public let delimiter: String?
    public let wordColumn: Int?
    public let definitionColumn: Int?

    public init(
        id: String,
        type: SourceType,
        path: String,
        license: String,
        attribution: String,
        sourceURL: String?,
        priority: Int,
        delimiter: String? = nil,
        wordColumn: Int? = nil,
        definitionColumn: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.path = path
        self.license = license
        self.attribution = attribution
        self.sourceURL = sourceURL
        self.priority = priority
        self.delimiter = delimiter
        self.wordColumn = wordColumn
        self.definitionColumn = definitionColumn
    }
}

public enum SourceType: String, Codable, Equatable, Sendable {
    case kaikkiJSONL = "kaikki-jsonl"
    case tsv
}

public struct DatabaseBuildSummary: Equatable, Sendable {
    public let outputDatabasePath: String
    public let totalRows: Int
    public let inserted: Int
    public let updated: Int
    public let skipped: Int

    public init(outputDatabasePath: String, totalRows: Int, inserted: Int, updated: Int, skipped: Int) {
        self.outputDatabasePath = outputDatabasePath
        self.totalRows = totalRows
        self.inserted = inserted
        self.updated = updated
        self.skipped = skipped
    }
}
