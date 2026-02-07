import Foundation

public enum CommandRunner {
    public static func run(arguments: [String]) throws -> String {
        guard let command = arguments.first else {
            return usageText
        }

        switch command {
        case "build-db":
            return try runBuildDatabase(arguments: Array(arguments.dropFirst()))
        case "build-manifest":
            return try runBuildManifest(arguments: Array(arguments.dropFirst()))
        case "verify-manifest":
            return try runVerifyManifest(arguments: Array(arguments.dropFirst()))
        case "derive-public-key":
            return try runDerivePublicKey(arguments: Array(arguments.dropFirst()))
        case "help", "--help", "-h":
            return usageText
        default:
            throw NSError(domain: "DictionaryBuilder", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown command: \(command)\n\n\(usageText)"])
        }
    }

    public static let usageText = """
    dictionary-builder commands:
      build-db --config <path-to-build-config.json>
      build-manifest --db <path-to-db> --url <https-url> --version-code <int> --version-name <string> --private-key-hex <hex> [--published-at <iso-8601>] [--output <manifest.json>]
      verify-manifest --manifest <path-to-manifest.json> --public-key-hex <hex>
      derive-public-key --private-key-hex <hex>
    """

    private static func runBuildDatabase(arguments: [String]) throws -> String {
        let options = parseFlagPairs(arguments)
        guard let configPath = options["--config"] else {
            throw NSError(domain: "DictionaryBuilder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing --config flag"])
        }

        let configData = try Data(contentsOf: URL(fileURLWithPath: expandedPath(configPath)))
        let config = try JSONDecoder().decode(BuildDatabaseConfig.self, from: configData)
        let summary = try DatabaseBuilder.build(config: config)

        return "Built \(summary.outputDatabasePath) rows=\(summary.totalRows) inserted=\(summary.inserted) updated=\(summary.updated) skipped=\(summary.skipped)"
    }

    private static func runBuildManifest(arguments: [String]) throws -> String {
        let options = parseFlagPairs(arguments)

        guard
            let dbPath = options["--db"],
            let databaseURL = options["--url"],
            let versionCodeRaw = options["--version-code"],
            let versionCode = Int(versionCodeRaw),
            let versionName = options["--version-name"],
            let privateKeyHex = options["--private-key-hex"]
        else {
            throw NSError(domain: "DictionaryBuilder", code: 4, userInfo: [NSLocalizedDescriptionKey: "Missing required build-manifest flags"])
        }

        let publishedAt = options["--published-at"] ?? ISO8601DateFormatter().string(from: Date())
        let outputPath = expandedPath(options["--output"] ?? "manifest.json")
        let dbData = try Data(contentsOf: URL(fileURLWithPath: expandedPath(dbPath)))

        let manifest = try ManifestBuilder.buildSignedManifest(
            dbData: dbData,
            databaseURL: databaseURL,
            versionCode: versionCode,
            versionName: versionName,
            publishedAt: publishedAt,
            privateKeyHex: privateKeyHex
        )

        let encoded = try JSONEncoder.pretty.encode(manifest)
        try encoded.write(to: URL(fileURLWithPath: outputPath), options: .atomic)

        return "Manifest written to \(outputPath) (versionCode=\(manifest.release.versionCode))"
    }

    private static func runVerifyManifest(arguments: [String]) throws -> String {
        let options = parseFlagPairs(arguments)
        guard let manifestPath = options["--manifest"], let publicKeyHex = options["--public-key-hex"] else {
            throw NSError(domain: "DictionaryBuilder", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing --manifest or --public-key-hex"])
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: expandedPath(manifestPath)))
        let manifest = try JSONDecoder().decode(DatabaseUpdateManifest.self, from: data)
        let valid = ManifestSecurityCompat.verifySignature(manifest: manifest, publicKeyHex: publicKeyHex)

        guard valid else {
            throw NSError(domain: "DictionaryBuilder", code: 6, userInfo: [NSLocalizedDescriptionKey: "Signature invalid"])
        }

        return "Signature valid"
    }

    private static func runDerivePublicKey(arguments: [String]) throws -> String {
        let options = parseFlagPairs(arguments)
        guard let privateKeyHex = options["--private-key-hex"] else {
            throw NSError(domain: "DictionaryBuilder", code: 7, userInfo: [NSLocalizedDescriptionKey: "Missing --private-key-hex"])
        }

        return try ManifestSecurityCompat.derivePublicKeyHex(privateKeyHex: privateKeyHex)
    }

    private static func parseFlagPairs(_ arguments: [String]) -> [String: String] {
        var options: [String: String] = [:]
        var index = 0

        while index < arguments.count {
            let current = arguments[index]
            if current.hasPrefix("--") && index + 1 < arguments.count {
                options[current] = arguments[index + 1]
                index += 2
            } else {
                index += 1
            }
        }

        return options
    }

    private static func expandedPath(_ raw: String) -> String {
        (raw as NSString).expandingTildeInPath
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
