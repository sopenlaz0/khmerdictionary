# dictionary-builder

Build and sign enriched Khmer dictionary SQLite releases for the iOS app.

## What it does

- Imports external sources (`kaikki-jsonl`, `tsv`)
- Normalizes and deduplicates by word
- Applies deterministic winner rules:
  - higher `priority` wins
  - if tied, longer definition wins
- Produces an output SQLite database compatible with the app (`dict(id, word, definition)`)
- Stores provenance in `dict_attribution(word_id, source_id, license, attribution, source_url, imported_at)`
- Generates signed update manifests compatible with app verification

## Build

```bash
cd /Users/sopen/Documents/hobby/dictionary/khmerdictionary-ios/tools/dictionary-builder
swift build
```

## 1) Build enriched DB

```bash
swift run dictionary-builder build-db --config ./examples/build-config.example.json
```

Example config fields:
- `baseDatabasePath`: source DB to start from
- `outputDatabasePath`: generated DB path
- `sources[]`:
  - `id`, `type`, `path`, `license`, `attribution`, `sourceURL`, `priority`
  - optional for `tsv`: `delimiter`, `wordColumn`, `definitionColumn`

## 2) Build signed manifest

```bash
swift run dictionary-builder build-manifest \
  --db ./build/dict-v2.db \
  --url https://cdn.example.com/khmerdict/dict-v2.db \
  --version-code 2 \
  --version-name 2.0.0 \
  --private-key-hex <32-byte-ed25519-private-key-hex> \
  --published-at 2026-02-07T12:00:00Z \
  --output ./build/manifest-v2.json
```

## 3) Verify manifest signature

```bash
swift run dictionary-builder verify-manifest \
  --manifest ./build/manifest-v2.json \
  --public-key-hex <32-byte-ed25519-public-key-hex>
```

## 4) Derive public key from private key

```bash
swift run dictionary-builder derive-public-key \
  --private-key-hex <32-byte-ed25519-private-key-hex>
```

## Source licensing notes

- Keep `license` and `attribution` fields accurate per source.
- Only ship datasets whose redistribution terms are compatible with App Store distribution.
- For Wiktionary-derived imports, retain required attribution in release metadata and app/legal docs.
