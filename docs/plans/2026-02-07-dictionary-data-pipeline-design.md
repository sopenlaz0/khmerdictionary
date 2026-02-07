# Dictionary Data Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a deterministic import + dedupe + signing pipeline for expanding Khmer dictionary coverage while preserving app update signature compatibility.

**Architecture:** A standalone Swift Package (`tools/dictionary-builder`) provides parsing, normalization, merge logic, SQLite writeback, and manifest signing/verification commands. The iOS runtime remains unchanged and consumes generated DB + manifest artifacts.

**Tech Stack:** Swift 6.2, Foundation, CryptoKit, SQLite3, Swift Testing.

---

### Task 1: Create a standalone builder package

**Files:**
- Modify: `tools/dictionary-builder/Package.swift`
- Create: `tools/dictionary-builder/Sources/DictionaryBuilderCore/*`
- Modify: `tools/dictionary-builder/Sources/dictionary-builder/dictionary_builder.swift`
- Create: `tools/dictionary-builder/Tests/DictionaryBuilderCoreTests/*`

### Task 2: Implement import + merge core

**Files:**
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/Models.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/KaikkiJSONLParser.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/TSVParser.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/DefinitionSanitizer.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/TextNormalization.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/MergeEngine.swift`

### Task 3: Implement database output and provenance

**Files:**
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/DatabaseBuilder.swift`

### Task 4: Implement manifest signing and verification compatibility

**Files:**
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/ManifestSecurityCompat.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/ManifestBuilder.swift`
- `tools/dictionary-builder/Sources/DictionaryBuilderCore/CommandRunner.swift`

### Task 5: Document usage and config

**Files:**
- Create: `tools/dictionary-builder/README.md`
- Create: `tools/dictionary-builder/examples/build-config.example.json`
- Modify: `README.md`

### Verification

- `swift test` in `tools/dictionary-builder`
- `swift run dictionary-builder help`
- End-to-end smoke run with temp config:
  - `build-db`
  - `build-manifest`
  - `verify-manifest`
