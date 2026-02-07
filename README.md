# Khmer Dictionary (Native iOS)

Swift-only iOS app for Khmer dictionary lookup and offline usage.

## Stack

- Swift 6
- SwiftUI
- GRDB + SQLite
- CryptoKit-based verification for signed dictionary updates
- XcodeGen (`project.yml`) for project generation

## Requirements

- Xcode 17+
- iOS 26 SDK

## Run In Xcode

1. Open:
   `/Users/username/Documents/hobby/dictionary/khmerdictionary-ios/KhmerDictionary.xcodeproj`
2. Select scheme: `KhmerDictionary`
3. Run on an iPhone simulator or device

## Run Tests (CLI)

```bash
cd /Users/username/Documents/hobby/dictionary/khmerdictionary-ios
xcodebuild -scheme KhmerDictionary -project KhmerDictionary.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Optional: Regenerate Project

```bash
cd /Users/username/Documents/hobby/dictionary/khmerdictionary-ios
xcodegen generate
```

## Dictionary Update Manifest Contract

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

Signing payload format:
`schemaVersion\nversionCode\nversionName\npublishedAt\nurl\nsha256\nsizeBytes`<p align="center">
  <img src="https://github.com/user-attachments/assets/7e114f86-48bd-4cf9-89b3-6c21d4a910a9" width="220" alt="Simulator screenshot 1">
  <img src="https://github.com/user-attachments/assets/89d95789-0480-4b52-9ba0-80d52e1f197c" width="220" alt="Simulator screenshot 2">
  <img src="https://github.com/user-attachments/assets/5a514f1d-0761-4877-8964-8c744cea6343" width="220" alt="Simulator screenshot 3">
  <img src="https://github.com/user-attachments/assets/b2ea875b-fc66-46b4-9314-a1cf54b0cd38" width="220" alt="Simulator screenshot 4">
</p>
