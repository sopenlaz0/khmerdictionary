import XCTest
@testable import KhmerDictionary

final class ManifestParsingTests: XCTestCase {
    func testParseValidManifest() throws {
        let raw: [String: Any] = [
            "schemaVersion": 1,
            "release": [
                "versionCode": 2,
                "versionName": "2.0.0",
                "publishedAt": "2026-02-07T12:00:00.000Z"
            ],
            "database": [
                "url": "https://example.com/dict-v2.db",
                "sha256": String(repeating: "A", count: 64),
                "sizeBytes": 12345,
                "signatureHex": String(repeating: "B", count: 128)
            ]
        ]

        let manifest = try ManifestParser.parse(raw)
        XCTAssertEqual(manifest.schemaVersion, 1)
        XCTAssertEqual(manifest.release.versionCode, 2)
        XCTAssertEqual(manifest.database.sha256, String(repeating: "a", count: 64))
        XCTAssertEqual(manifest.database.signatureHex, String(repeating: "b", count: 128))
    }

    func testParseRejectsNonHttpsURL() {
        let raw: [String: Any] = [
            "schemaVersion": 1,
            "release": ["versionCode": 2, "versionName": "2.0.0", "publishedAt": "2026-02-07T12:00:00.000Z"],
            "database": [
                "url": "http://example.com/dict-v2.db",
                "sha256": String(repeating: "a", count: 64),
                "sizeBytes": 12345,
                "signatureHex": String(repeating: "b", count: 128)
            ]
        ]

        XCTAssertThrowsError(try ManifestParser.parse(raw))
    }

    func testParseRejectsInvalidSignatureHexLength() {
        let raw: [String: Any] = [
            "schemaVersion": 1,
            "release": ["versionCode": 2, "versionName": "2.0.0", "publishedAt": "2026-02-07T12:00:00.000Z"],
            "database": [
                "url": "https://example.com/dict-v2.db",
                "sha256": String(repeating: "a", count: 64),
                "sizeBytes": 12345,
                "signatureHex": "1234"
            ]
        ]

        XCTAssertThrowsError(try ManifestParser.parse(raw))
    }
}
