import Foundation

public enum ManifestBuilderError: LocalizedError {
    case invalidVersionCode
    case invalidVersionName
    case invalidDatabaseURL
    case invalidPrivateKey
    case invalidPublishedAt

    public var errorDescription: String? {
        switch self {
        case .invalidVersionCode:
            return "versionCode must be positive"
        case .invalidVersionName:
            return "versionName must not be empty"
        case .invalidDatabaseURL:
            return "databaseURL must be https"
        case .invalidPrivateKey:
            return "privateKeyHex must be a 32-byte hex ed25519 secret key"
        case .invalidPublishedAt:
            return "publishedAt must be valid ISO-8601"
        }
    }
}

public enum ManifestBuilder {
    public static func buildSignedManifest(
        dbData: Data,
        databaseURL: String,
        versionCode: Int,
        versionName: String,
        publishedAt: String,
        privateKeyHex: String,
        schemaVersion: Int = 1
    ) throws -> DatabaseUpdateManifest {
        guard versionCode > 0 else {
            throw ManifestBuilderError.invalidVersionCode
        }

        guard !versionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ManifestBuilderError.invalidVersionName
        }

        guard let url = URL(string: databaseURL), url.scheme?.lowercased() == "https" else {
            throw ManifestBuilderError.invalidDatabaseURL
        }

        guard isValidISO8601(publishedAt) else {
            throw ManifestBuilderError.invalidPublishedAt
        }

        let sha256 = ManifestSecurityCompat.sha256Hex(for: dbData)

        var manifest = DatabaseUpdateManifest(
            schemaVersion: schemaVersion,
            release: .init(
                versionCode: versionCode,
                versionName: versionName,
                publishedAt: publishedAt
            ),
            database: .init(
                url: url.absoluteString,
                sha256: sha256,
                sizeBytes: dbData.count,
                signatureHex: String(repeating: "0", count: 128)
            )
        )

        let payload = ManifestSecurityCompat.buildSigningPayload(manifest)
        let signatureHex = try ManifestSecurityCompat.signPayload(payload: payload, privateKeyHex: privateKeyHex)

        manifest = DatabaseUpdateManifest(
            schemaVersion: manifest.schemaVersion,
            release: manifest.release,
            database: .init(
                url: manifest.database.url,
                sha256: manifest.database.sha256,
                sizeBytes: manifest.database.sizeBytes,
                signatureHex: signatureHex
            )
        )

        return manifest
    }

    private static func isValidISO8601(_ value: String) -> Bool {
        let formatterA = ISO8601DateFormatter()
        formatterA.formatOptions = [.withInternetDateTime]
        if formatterA.date(from: value) != nil {
            return true
        }

        let formatterB = ISO8601DateFormatter()
        formatterB.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatterB.date(from: value) != nil
    }
}
