import Foundation

enum UpdateCheckResult: Equatable, Sendable {
    case missingConfig(message: String)
    case upToDate(currentVersionCode: Int?, remoteVersionCode: Int)
    case staged(remoteVersionCode: Int, restartRequired: Bool)
    case error(message: String)
}

struct DatabaseUpdateService: Sendable {
    private let manifestURL: URL?
    private let publicKeyHex: String?
    private let updatesDirectory: URL

    init(
        manifestURL: URL?,
        publicKeyHex: String?,
        updatesDirectory: URL
    ) {
        self.manifestURL = manifestURL
        self.publicKeyHex = publicKeyHex
        self.updatesDirectory = updatesDirectory
    }

    func pendingVersionCode() -> Int? {
        StagedUpdateStore.pendingUpdateVersionCode(updatesDirectory: updatesDirectory)
    }

    func checkAndStageUpdate(currentVersionCode: Int?) async -> UpdateCheckResult {
        guard let manifestURL, let publicKeyHex else {
            return .missingConfig(message: "Update manifest URL or public key is not configured.")
        }

        guard publicKeyHex.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil else {
            return .missingConfig(message: "Configured update public key must be a 64-char hex ed25519 key.")
        }

        do {
            let (manifestData, response) = try await URLSession.shared.data(from: manifestURL)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                return .error(message: "Manifest request failed")
            }

            let manifest = try ManifestParser.parseJSON(data: manifestData)
            guard ManifestSecurity.verifySignature(manifest: manifest, publicKeyHex: publicKeyHex) else {
                return .error(message: "Manifest signature verification failed.")
            }

            guard ManifestSecurity.isNewerRelease(manifest: manifest, currentVersionCode: currentVersionCode) else {
                return .upToDate(currentVersionCode: currentVersionCode, remoteVersionCode: manifest.release.versionCode)
            }

            guard let databaseURL = URL(string: manifest.database.url) else {
                return .error(message: "database.url must be a valid URL")
            }

            let (databaseData, databaseResponse) = try await URLSession.shared.data(from: databaseURL)
            guard let dbResponse = databaseResponse as? HTTPURLResponse,
                  (200...299).contains(dbResponse.statusCode)
            else {
                return .error(message: "Database download failed")
            }

            let actualHash = ManifestSecurity.sha256Hex(for: databaseData)
            guard actualHash == manifest.database.sha256.lowercased() else {
                return .error(message: "Downloaded DB checksum did not match manifest")
            }

            guard databaseData.count == manifest.database.sizeBytes else {
                return .error(message: "Downloaded DB size did not match manifest")
            }

            try StagedUpdateStore.stageDownloadedDatabase(
                manifest: manifest,
                downloadedData: databaseData,
                updatesDirectory: updatesDirectory
            )

            return .staged(remoteVersionCode: manifest.release.versionCode, restartRequired: true)
        } catch {
            return .error(message: error.localizedDescription)
        }
    }
}
