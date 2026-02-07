# Khmer Dictionary Expo Modernization Design

**Goal:** Replatform Khmer Dictionary from legacy Android/Kotlin into a cross-platform Expo app with modern UX and stronger long-term maintainability.

## Architecture decisions

- Use Expo managed workflow for faster iteration and lower native maintenance overhead.
- Use Expo Router for file-based navigation and modular feature ownership.
- Use Expo SQLite with a bundled preloaded dictionary database for offline-first behavior.
- Keep mutable user data (`bookmarks`, `history`) in dedicated SQLite tables instead of mutating source dictionary rows.

## UI direction

- iOS: translucent glass panels and layered gradients to align with liquid-glass visual language.
- Android: Material 3 surfaces, clear hierarchy, and elevated cards.
- Khmer typography: migrated original Khmer fonts and applied app-wide.

## Data strategy

- Source dictionary is bundled as `assets/data/dict.db` for first run.
- Runtime tables:
  - `bookmarks(word_id, created_at)`
  - `history(word_id, viewed_at)`
- Future update channel: signed/hashed remote payloads, validated before replacement.

## Testing strategy

- Unit tests for dictionary formatting/search utility behavior.
- Add repository-level SQLite integration tests next.
- Add smoke navigation tests (search -> detail -> bookmark -> tabs).

## Migration phases

1. Baseline shell + navigation + local DB search (completed).
2. Bookmark/history parity and persistence (completed baseline).
3. Definition rendering parity refinements and link semantics.
4. Signed remote DB update pipeline.
5. CI hardening, analytics/monitoring, and release automation.
