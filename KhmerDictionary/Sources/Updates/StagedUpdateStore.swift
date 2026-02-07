import Foundation

struct PendingUpdateMetadata: Codable, Sendable {
    let manifest: DatabaseUpdateManifest
    let stagedAt: String
}

enum StagedUpdateStore {
    static func applyPendingUpdateIfAvailable(
        fileManager: FileManager = .default,
        updatesDirectory: URL,
        activeDatabaseURL: URL
    ) -> (appliedVersionCode: Int?, errorMessage: String?) {
        let stagedDatabaseURL = updatesDirectory.appendingPathComponent("dict.staged.db")
        let pendingMetadataURL = updatesDirectory.appendingPathComponent("pending-update.json")

        guard fileManager.fileExists(atPath: stagedDatabaseURL.path),
              let pending = readPendingMetadata(fileManager: fileManager, metadataURL: pendingMetadataURL)
        else {
            clearPendingMetadata(fileManager: fileManager, metadataURL: pendingMetadataURL)
            return (nil, nil)
        }

        do {
            try ensureDirectory(fileManager: fileManager, at: activeDatabaseURL.deletingLastPathComponent())
            let backupURL = activeDatabaseURL.deletingPathExtension().appendingPathExtension("bak")

            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }

            if fileManager.fileExists(atPath: activeDatabaseURL.path) {
                try fileManager.moveItem(at: activeDatabaseURL, to: backupURL)
            }

            do {
                try fileManager.moveItem(at: stagedDatabaseURL, to: activeDatabaseURL)
                if fileManager.fileExists(atPath: backupURL.path) {
                    try fileManager.removeItem(at: backupURL)
                }
                clearPendingMetadata(fileManager: fileManager, metadataURL: pendingMetadataURL)
                return (pending.manifest.release.versionCode, nil)
            } catch {
                if fileManager.fileExists(atPath: backupURL.path) {
                    try? fileManager.moveItem(at: backupURL, to: activeDatabaseURL)
                }
                return (nil, "Failed to apply staged update: \(error.localizedDescription)")
            }
        } catch {
            return (nil, "Failed to apply staged update: \(error.localizedDescription)")
        }
    }

    static func stageDownloadedDatabase(
        manifest: DatabaseUpdateManifest,
        downloadedData: Data,
        fileManager: FileManager = .default,
        updatesDirectory: URL
    ) throws {
        try ensureDirectory(fileManager: fileManager, at: updatesDirectory)

        let stagedDatabaseURL = updatesDirectory.appendingPathComponent("dict.staged.db")
        let pendingMetadataURL = updatesDirectory.appendingPathComponent("pending-update.json")

        if fileManager.fileExists(atPath: stagedDatabaseURL.path) {
            try fileManager.removeItem(at: stagedDatabaseURL)
        }

        try downloadedData.write(to: stagedDatabaseURL, options: .atomic)
        let metadata = PendingUpdateMetadata(manifest: manifest, stagedAt: ISO8601DateFormatter().string(from: Date()))
        let encoded = try JSONEncoder().encode(metadata)
        try encoded.write(to: pendingMetadataURL, options: .atomic)
    }

    static func pendingUpdateVersionCode(
        fileManager: FileManager = .default,
        updatesDirectory: URL
    ) -> Int? {
        let pendingMetadataURL = updatesDirectory.appendingPathComponent("pending-update.json")
        return readPendingMetadata(fileManager: fileManager, metadataURL: pendingMetadataURL)?.manifest.release.versionCode
    }

    private static func readPendingMetadata(fileManager: FileManager, metadataURL: URL) -> PendingUpdateMetadata? {
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: metadataURL)
            return try JSONDecoder().decode(PendingUpdateMetadata.self, from: data)
        } catch {
            return nil
        }
    }

    private static func clearPendingMetadata(fileManager: FileManager, metadataURL: URL) {
        if fileManager.fileExists(atPath: metadataURL.path) {
            try? fileManager.removeItem(at: metadataURL)
        }
    }

    private static func ensureDirectory(fileManager: FileManager, at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
