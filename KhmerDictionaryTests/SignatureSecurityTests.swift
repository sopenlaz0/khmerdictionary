import CryptoKit
import XCTest
@testable import KhmerDictionary

final class SignatureSecurityTests: XCTestCase {
    func testBuildSigningPayloadMatchesContract() {
        let manifest = DatabaseUpdateManifest(
            schemaVersion: 1,
            release: .init(versionCode: 2, versionName: "2.0.0", publishedAt: "2026-02-07T12:00:00.000Z"),
            database: .init(
                url: "https://example.com/dict-v2.db",
                sha256: String(repeating: "a", count: 64),
                sizeBytes: 12345,
                signatureHex: String(repeating: "0", count: 128)
            )
        )

        let payload = ManifestSecurity.buildSigningPayload(manifest)
        let expected = """
        1
        2
        2.0.0
        2026-02-07T12:00:00.000Z
        https://example.com/dict-v2.db
        \(String(repeating: "a", count: 64))
        12345
        """

        XCTAssertEqual(payload, expected)
    }

    func testVerifySignatureSuccess() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKeyHex = privateKey.publicKey.rawRepresentation.map { String(format: "%02x", $0) }.joined()

        var manifest = DatabaseUpdateManifest(
            schemaVersion: 1,
            release: .init(versionCode: 2, versionName: "2.0.0", publishedAt: "2026-02-07T12:00:00.000Z"),
            database: .init(
                url: "https://example.com/dict-v2.db",
                sha256: String(repeating: "a", count: 64),
                sizeBytes: 12345,
                signatureHex: ""
            )
        )

        let payload = ManifestSecurity.buildSigningPayload(manifest)
        let signature = try privateKey.signature(for: Data(payload.utf8))
        manifest.database.signatureHex = signature.map { String(format: "%02x", $0) }.joined()

        XCTAssertTrue(ManifestSecurity.verifySignature(manifest: manifest, publicKeyHex: publicKeyHex))
    }

    func testSHA256HexMatchesKnownValue() {
        let digest = ManifestSecurity.sha256Hex(for: Data("abc".utf8))
        XCTAssertEqual(digest, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
