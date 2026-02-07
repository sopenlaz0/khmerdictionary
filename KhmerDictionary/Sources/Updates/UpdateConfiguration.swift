import Foundation

enum UpdateConfiguration {
    static let bundledDictionaryVersionCode = 1
    static let databaseFileName = "dict.db"

    static var manifestURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "UpdatesManifestURL") as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return URL(string: trimmed)
    }

    static var publicKeyHex: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "UpdatesPublicKeyHex") as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            return nil
        }

        return trimmed
    }
}
