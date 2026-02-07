import Foundation

struct DatabaseUpdateManifest: Equatable, Codable, Sendable {
    struct Release: Equatable, Codable, Sendable {
        let versionCode: Int
        let versionName: String
        let publishedAt: String
    }

    struct Database: Equatable, Codable, Sendable {
        let url: String
        let sha256: String
        let sizeBytes: Int
        var signatureHex: String
    }

    let schemaVersion: Int
    let release: Release
    var database: Database
}
