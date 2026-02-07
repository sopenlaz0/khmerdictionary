# KhmerDict (Expo)

Modernized Khmer Dictionary app using React Native + Expo, migrated from the legacy Android codebase.

## Tech stack

- Expo SDK 54 (React Native 0.81)
- Expo Router
- Expo SQLite (bundled preloaded DB)
- React Native Paper (Material 3)
- iOS glass-style surfaces via `expo-blur`

## Run locally

1. Install dependencies

```bash
npm install
```

2. Start dev server

```bash
npm run start
```

3. Run on platform

```bash
npm run ios
npm run android
npm run web
```

## Validation

```bash
npx expo-doctor
npx tsc --noEmit
npm test
```

## Notes

- Recommended Node version: `20.19.4` or newer patch in the 20.x line.
- Current workspace is on `20.19.3`, which triggers `EBADENGINE` warnings from RN/Metro but still installs.
- Dictionary database and Khmer fonts were migrated from the legacy repo into `assets/data` and `assets/fonts`.

## Current feature parity slice

- Search words from local SQLite dictionary
- View word definition
- Bookmark words
- View bookmarked words
- View history of opened words
- Phase 2 update pipeline: signed manifest validation + SHA-256 DB verification + staged apply on next app restart

## Phase 2 Setup

Configure your update source in `/Users/sopen/Documents/hobby/dictionary/khmerdict/app.json`:

- `expo.extra.updates.manifestUrl`: HTTPS URL to manifest JSON
- `expo.extra.updates.publicKeyHex`: ed25519 public key in 64-char hex

Manifest format:

```json
{
  "schemaVersion": 1,
  "release": {
    "versionCode": 2,
    "versionName": "2.0.0",
    "publishedAt": "2026-02-07T12:00:00.000Z"
  },
  "database": {
    "url": "https://cdn.example.com/khmerdict/dict-v2.db",
    "sha256": "64-char-lowercase-hex",
    "sizeBytes": 18399321,
    "signatureHex": "128-char-lowercase-hex"
  }
}
```

Signature payload format (newline-delimited):

`schemaVersion\\nversionCode\\nversionName\\npublishedAt\\nurl\\nsha256\\nsizeBytes`

## Next milestones

- Add theme controls (iOS glass emphasis vs Android Material emphasis)
- Add integration tests for search/detail/bookmark/history flows
- Add CI workflow for test + typecheck + doctor
# khmerdictionary
