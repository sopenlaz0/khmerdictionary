import CryptoKit
import Foundation

public enum ManifestSecurityCompat {
    public static func buildSigningPayload(_ manifest: DatabaseUpdateManifest) -> String {
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

    public static func verifySignature(manifest: DatabaseUpdateManifest, publicKeyHex: String) -> Bool {
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

    public static func sha256Hex(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func signPayload(payload: String, privateKeyHex: String) throws -> String {
        let privateKeyData = try Data(hex: privateKeyHex)
        guard privateKeyData.count == 32 else {
            throw ManifestBuilderError.invalidPrivateKey
        }

        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        let signature = try privateKey.signature(for: Data(payload.utf8))
        return signature.hexString
    }

    public static func derivePublicKeyHex(privateKeyHex: String) throws -> String {
        let privateKeyData = try Data(hex: privateKeyHex)
        guard privateKeyData.count == 32 else {
            throw ManifestBuilderError.invalidPrivateKey
        }

        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
        return privateKey.publicKey.rawRepresentation.hexString
    }
}

enum HexError: Error {
    case invalidLength
    case invalidCharacters
}

extension Data {
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
            let next = normalized.index(index, offsetBy: 2)
            let byte = normalized[index..<next]
            guard let parsed = UInt8(byte, radix: 16) else {
                throw HexError.invalidCharacters
            }
            data.append(parsed)
            index = next
        }

        self = data
    }

    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
