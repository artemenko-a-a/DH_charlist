# DH_charlist

Bootstrap/foundation repository for a Dark Heresy II character manager (iPhone/iPad-first scope).

> Current state: this is **not a completed MVP**. It now includes one validated vertical slice for character lifecycle on top of local JSON persistence.

## Delivered so far
- Pure domain models for character sheet sections (domain independent from SwiftUI/SwiftData).
- Repository and import/export contracts.
- Local JSON persistence adapter (`JSONFileCharacterRepository`) as the validated local path.
- SwiftData adapter placeholder (availability-gated; runtime validation blocked in this environment).
- SwiftUI app-facing shell + composition root (`AppContainer`) + character vertical slice screens:
  - character list with real repository loading;
  - create character;
  - open character details;
  - edit profile with debounced/coalesced autosave;
  - duplicate and delete actions;
  - overview fields: name, home world, background, role, updatedAt.
- Tests for derived values, import/export schema behavior, and character lifecycle persistence flows.

## Not delivered yet
- Full MVP feature depth across skills/combat/session/import-export UI and runtime accessibility validation.

## Run tests
```bash
swift test
```
