import Foundation

@MainActor
final class AppSession: ObservableObject {
    let repository: any DictionaryRepository
    let updateService: DatabaseUpdateService

    @Published var bootstrapErrorMessage: String?
    @Published private(set) var refreshVersion: Int = 0

    init(
        repository: any DictionaryRepository,
        updateService: DatabaseUpdateService,
        bootstrapErrorMessage: String?
    ) {
        self.repository = repository
        self.updateService = updateService
        self.bootstrapErrorMessage = bootstrapErrorMessage
    }

    static func bootstrap() throws -> AppSession {
        let bootstrapResult = try DatabaseBootstrapper.bootstrap()
        let repository = try GRDBDictionaryRepository(
            databaseURL: bootstrapResult.databaseURL,
            appliedVersionCode: bootstrapResult.appliedVersionCode
        )
        let updatesDirectory = try AppPaths.updatesDirectory()
        let updateService = DatabaseUpdateService(
            manifestURL: UpdateConfiguration.manifestURL,
            publicKeyHex: UpdateConfiguration.publicKeyHex,
            updatesDirectory: updatesDirectory
        )

        return AppSession(
            repository: repository,
            updateService: updateService,
            bootstrapErrorMessage: bootstrapResult.bootstrapErrorMessage
        )
    }

    func bumpRefresh() {
        refreshVersion &+= 1
    }
}
