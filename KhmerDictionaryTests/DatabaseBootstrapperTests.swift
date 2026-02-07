import Foundation
import Testing
@testable import KhmerDictionary

struct DatabaseBootstrapperTests {
    @Test
    func resolveBundledDatabaseURLPrefersDataSubdirectory() throws {
        let bundleURL = try makeTestBundle(hasDataDB: true, hasRootDB: true)
        let bundle = try #require(Bundle(url: bundleURL))

        let resolved = DatabaseBootstrapper.resolveBundledDatabaseURL(in: bundle)
        #expect(resolved?.path.hasSuffix("/Data/dict.db") == true)
    }

    @Test
    func resolveBundledDatabaseURLFallsBackToRoot() throws {
        let bundleURL = try makeTestBundle(hasDataDB: false, hasRootDB: true)
        let bundle = try #require(Bundle(url: bundleURL))

        let resolved = DatabaseBootstrapper.resolveBundledDatabaseURL(in: bundle)
        #expect(resolved?.lastPathComponent == "dict.db")
        #expect(resolved?.deletingLastPathComponent().lastPathComponent != "Data")
    }

    @Test
    func resolveBundledDatabaseURLReturnsNilWhenMissing() throws {
        let bundleURL = try makeTestBundle(hasDataDB: false, hasRootDB: false)
        let bundle = try #require(Bundle(url: bundleURL))

        #expect(DatabaseBootstrapper.resolveBundledDatabaseURL(in: bundle) == nil)
    }

    private func makeTestBundle(hasDataDB: Bool, hasRootDB: Bool) throws -> URL {
        let fileManager = FileManager.default
        let url = fileManager.temporaryDirectory
            .appendingPathComponent("KhmerDictionaryTests-\(UUID().uuidString)")
            .appendingPathExtension("bundle")
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        let infoPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <dict>
            <key>CFBundleIdentifier</key>
            <string>com.sopenlaz0.khmerdictionary.tests.bundle</string>
          </dict>
        </plist>
        """
        try infoPlist.data(using: .utf8)?.write(to: url.appendingPathComponent("Info.plist"))

        if hasDataDB {
            let dataURL = url.appendingPathComponent("Data")
            try fileManager.createDirectory(at: dataURL, withIntermediateDirectories: true)
            try Data("data-db".utf8).write(to: dataURL.appendingPathComponent("dict.db"))
        }

        if hasRootDB {
            try Data("root-db".utf8).write(to: url.appendingPathComponent("dict.db"))
        }

        return url
    }
}
