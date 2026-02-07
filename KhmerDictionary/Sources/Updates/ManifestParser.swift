import Foundation

enum ManifestParserError: LocalizedError {
    case invalidRoot
    case unsupportedSchemaVersion
    case invalidRelease
    case invalidDatabase
    case invalidVersionCode
    case invalidVersionName
    case invalidPublishedAt
    case invalidURL
    case invalidSHA256
    case invalidSizeBytes
    case invalidSignature

    var errorDescription: String? {
        switch self {
        case .invalidRoot:
            return "Manifest must be an object"
        case .unsupportedSchemaVersion:
            return "Unsupported schemaVersion"
        case .invalidRelease:
            return "release must be an object"
        case .invalidDatabase:
            return "database must be an object"
        case .invalidVersionCode:
            return "release.versionCode must be a positive integer"
        case .invalidVersionName:
            return "release.versionName must be a non-empty string"
        case .invalidPublishedAt:
            return "release.publishedAt must be a valid ISO date string"
        case .invalidURL:
            return "database.url must be an https URL"
        case .invalidSHA256:
            return "database.sha256 must be a 64-char hex string"
        case .invalidSizeBytes:
            return "database.sizeBytes must be a positive integer"
        case .invalidSignature:
            return "database.signatureHex must be a 128-char hex string"
        }
    }
}

enum ManifestParser {
    private static let shaRegex = try! NSRegularExpression(pattern: "^[0-9a-fA-F]{64}$")
    private static let sigRegex = try! NSRegularExpression(pattern: "^[0-9a-fA-F]{128}$")

    static func parseJSON(data: Data) throws -> DatabaseUpdateManifest {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = json as? [String: Any] else {
            throw ManifestParserError.invalidRoot
        }

        return try parse(dictionary)
    }

    static func parse(_ raw: [String: Any]) throws -> DatabaseUpdateManifest {
        guard let schemaVersion = raw["schemaVersion"] as? Int, schemaVersion == 1 else {
            throw ManifestParserError.unsupportedSchemaVersion
        }

        guard let release = raw["release"] as? [String: Any] else {
            throw ManifestParserError.invalidRelease
        }

        guard let database = raw["database"] as? [String: Any] else {
            throw ManifestParserError.invalidDatabase
        }

        guard let versionCode = toPositiveInt(release["versionCode"]) else {
            throw ManifestParserError.invalidVersionCode
        }

        guard let versionName = release["versionName"] as? String, !versionName.isEmpty else {
            throw ManifestParserError.invalidVersionName
        }

        guard let publishedAt = release["publishedAt"] as? String,
              isValidISO8601Date(publishedAt) else {
            throw ManifestParserError.invalidPublishedAt
        }

        guard let urlString = database["url"] as? String,
              let url = URL(string: urlString),
              url.scheme?.lowercased() == "https" else {
            throw ManifestParserError.invalidURL
        }

        guard let sha256 = database["sha256"] as? String,
              matches(regex: shaRegex, candidate: sha256) else {
            throw ManifestParserError.invalidSHA256
        }

        guard let sizeBytes = toPositiveInt(database["sizeBytes"]) else {
            throw ManifestParserError.invalidSizeBytes
        }

        guard let signatureHex = database["signatureHex"] as? String,
              matches(regex: sigRegex, candidate: signatureHex) else {
            throw ManifestParserError.invalidSignature
        }

        return DatabaseUpdateManifest(
            schemaVersion: schemaVersion,
            release: .init(versionCode: versionCode, versionName: versionName, publishedAt: publishedAt),
            database: .init(
                url: url.absoluteString,
                sha256: sha256.lowercased(),
                sizeBytes: sizeBytes,
                signatureHex: signatureHex.lowercased()
            )
        )
    }

    private static func toPositiveInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int, intValue > 0 {
            return intValue
        }

        if let number = value as? NSNumber {
            let intValue = number.intValue
            if intValue > 0, number.doubleValue.rounded() == number.doubleValue {
                return intValue
            }
        }

        if let string = value as? String, let intValue = Int(string), intValue > 0 {
            return intValue
        }

        return nil
    }

    private static func matches(regex: NSRegularExpression, candidate: String) -> Bool {
        let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
        return regex.firstMatch(in: candidate, options: [], range: range) != nil
    }

    private static func isValidISO8601Date(_ raw: String) -> Bool {
        let baseFormatter = ISO8601DateFormatter()
        baseFormatter.formatOptions = [.withInternetDateTime]
        if baseFormatter.date(from: raw) != nil {
            return true
        }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractionalFormatter.date(from: raw) != nil
    }
}
