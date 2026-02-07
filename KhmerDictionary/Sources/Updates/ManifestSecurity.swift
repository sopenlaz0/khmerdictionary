import CryptoKit
import Foundation

enum ManifestSecurity {
    static func buildSigningPayload(_ manifest: DatabaseUpdateManifest) -> String {
        [
            String(manifest.schemaVersion),
            String(manifest.release.versionCode),
            manifest.release.versionName,
            manifest.release.publishedAt,
            manifest.database.url,
            manifest.database.sha256.lowercased(),
            String(manifest.database.sizeBytes)
        ].joined(separator: "\n")
    }

    static func verifySignature(manifest: DatabaseUpdateManifest, publicKeyHex: String) -> Bool {
        do {
            let signature = try Data(hex: manifest.database.signatureHex)
            let publicKeyData = try Data(hex: publicKeyHex)
            guard signature.count == 64, publicKeyData.count == 32 else {
                return false
            }

            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
            let signedPayload = Data(buildSigningPayload(manifest).utf8)
            return publicKey.isValidSignature(signature, for: signedPayload)
        } catch {
            return false
        }
    }

    static func isNewerRelease(manifest: DatabaseUpdateManifest, currentVersionCode: Int?) -> Bool {
        guard let currentVersionCode else {
            return true
        }

        return manifest.release.versionCode > currentVersionCode
    }

    static func sha256Hex(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private enum HexError: Error {
    case invalidLength
    case invalidCharacters
}

private extension Data {
    init(hex: String) throws {
        guard hex.count % 2 == 0 else {
            throw HexError.invalidLength
        }

        let normalized = hex.lowercased()
        guard normalized.range(of: "^[0-9a-f]+$", options: .regularExpression) != nil else {
            throw HexError.invalidCharacters
        }

        var data = Data(capacity: normalized.count / 2)
        var index = normalized.startIndex
        while index < normalized.endIndex {
            let nextIndex = normalized.index(index, offsetBy: 2)
            let byteString = normalized[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else {
                throw HexError.invalidCharacters
            }

            data.append(byte)
            index = nextIndex
        }

        self = data
    }
}
