import CryptoKit
import Foundation
import Testing
@testable import DictionaryBuilderCore

struct ManifestSigningTests {
    @Test
    func buildsManifestAndVerifiesEd25519Signature() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let privateKeyHex = privateKey.rawRepresentation.hexString
        let publicKeyHex = privateKey.publicKey.rawRepresentation.hexString

        let dbData = Data("hello-db".utf8)
        let manifest = try ManifestBuilder.buildSignedManifest(
            dbData: dbData,
            databaseURL: "https://cdn.example.com/dict-v2.db",
            versionCode: 2,
            versionName: "2.0.0",
            publishedAt: "2026-02-07T12:00:00Z",
            privateKeyHex: privateKeyHex
        )

        #expect(manifest.database.sha256.count == 64)
        #expect(manifest.database.sizeBytes == dbData.count)
        #expect(ManifestSecurityCompat.verifySignature(manifest: manifest, publicKeyHex: publicKeyHex))
    }

    @Test
    func signingPayloadMatchesContractOrder() throws {
        let manifest = DatabaseUpdateManifest(
            schemaVersion: 1,
            release: .init(versionCode: 2, versionName: "2.0.0", publishedAt: "2026-02-07T12:00:00Z"),
            database: .init(
                url: "https://cdn.example.com/dict-v2.db",
                sha256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                sizeBytes: 123,
                signatureHex: String(repeating: "b", count: 128)
            )
        )

        let payload = ManifestSecurityCompat.buildSigningPayload(manifest)
        #expect(payload == "1\n2\n2.0.0\n2026-02-07T12:00:00Z\nhttps://cdn.example.com/dict-v2.db\naaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n123")
    }

    @Test
    func derivesPublicKeyFromPrivateKey() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let privateHex = privateKey.rawRepresentation.hexString

        let derived = try ManifestSecurityCompat.derivePublicKeyHex(privateKeyHex: privateHex)
        let expected = privateKey.publicKey.rawRepresentation.hexString
        #expect(derived == expected)
    }
}

private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
