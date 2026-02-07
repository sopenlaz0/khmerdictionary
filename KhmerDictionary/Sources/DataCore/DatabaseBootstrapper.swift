import Foundation

struct DatabaseBootstrapResult: Sendable {
    let databaseURL: URL
    let appliedVersionCode: Int?
    let bootstrapErrorMessage: String?
}

enum DatabaseBootstrapper {
    static func bootstrap(fileManager: FileManager = .default) throws -> DatabaseBootstrapResult {
        let databaseURL = try AppPaths.databaseURL(fileManager: fileManager)
        let updatesDirectory = try AppPaths.updatesDirectory(fileManager: fileManager)

        let stagedResult = StagedUpdateStore.applyPendingUpdateIfAvailable(
            fileManager: fileManager,
            updatesDirectory: updatesDirectory,
            activeDatabaseURL: databaseURL
        )

        if !fileManager.fileExists(atPath: databaseURL.path) {
            try copyBundledDatabase(to: databaseURL, fileManager: fileManager)
        }

        return DatabaseBootstrapResult(
            databaseURL: databaseURL,
            appliedVersionCode: stagedResult.appliedVersionCode,
            bootstrapErrorMessage: stagedResult.errorMessage
        )
    }

    private static func copyBundledDatabase(to destinationURL: URL, fileManager: FileManager) throws {
        guard let bundledURL = resolveBundledDatabaseURL(in: .main) else {
            throw NSError(
                domain: "KhmerDictionary.DatabaseBootstrapper",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Bundled dictionary database not found."]
            )
        }

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: bundledURL, to: destinationURL)
    }

    static func resolveBundledDatabaseURL(in bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: "dict", withExtension: "db", subdirectory: "Data") {
            return url
        }
        return bundle.url(forResource: "dict", withExtension: "db")
    }
}
