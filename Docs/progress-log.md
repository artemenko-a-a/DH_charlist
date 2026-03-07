# Progress Log

## 2026-03-07

### Batch 0 — Repo inspection + bootstrap
- **status:** validated
- **checks run:** `pwd`, file inventory, baseline read of `README.md`
- **results:** repository was nearly empty; bootstrap required.
- **blockers:** none.

### Batch 1 — Domain core
- **status:** validated
- **checks run:** `swift test`
- **results:** domain entities + derived calculations compile and tests pass.
- **blockers:** none.

### Batch 2 — Repository and import/export contracts
- **status:** validated
- **checks run:** `swift test`
- **results:** repository protocols and JSON DTO envelope/schema checks implemented.
- **blockers:** none.

### Batch 3 — SwiftData persistence adapter
- **status:** blocked
- **checks run:** `swift test`
- **results:** availability-gated SwiftData adapter placeholder exists; JSON file repository remains the validated local persistence path.
- **blockers:** SwiftData runtime validation is not executable in this environment.

### Batch 4 — App shell + navigation foundation
- **status:** validated
- **checks run:** `swift test`
- **results:** SwiftUI-gated tab shell/navigation foundation exists and compiles in package context.
- **blockers:** iOS simulator/UI runtime unavailable here.

### Batch 5 — Character vertical slice (list/create/open/edit/delete/duplicate)
- **status:** validated
- **checks run:** `swift test`
- **results:** end-to-end flow implemented on JSON repository: list load, create, open details, profile autosave edit, duplicate, delete.
- **blockers:** iOS simulator/runtime validation blocked here (`xcodebuild` unavailable).

### Batch 5 corrective pass — Architecture/state/autosave hardening
- **status:** validated
- **checks run:** `swift test`, `swift build`, `xcodebuild -list`
- **results:** presentation no longer constructs infrastructure directly; detail/profile now use `characterID` + shared state source; autosave is debounced/coalesced; targeted tests pass.
- **blockers:** iOS simulator/runtime validation blocked here (`xcodebuild` unavailable).

### Batch 5 corrective micro-pass — Fix autosave tracking race
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** restored `SwiftUI.App` conformance by adding explicit `public init()` to `DHCharListIOSAppHost` while keeping container injection initializer; both required validation commands pass and autosave-focused tests pass.
- **blockers:** none.

### Batch 6 — Characteristics/resources UI depth
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** implemented editable characteristics + resources screen in the accepted character detail flow using `characterID` + shared observable state; derived characteristic bonuses and `experienceAvailable` now render from live edited values; edits persist via use cases into the validated JSON-backed repository path; added tests covering characteristic/resource persistence and derived values.
- **blockers:** none.

### Batch 7 — Skills UI depth
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** integrated a full skills screen into the accepted character detail flow using `characterID` + shared observable state; implemented skills CRUD (add/edit/delete), editable fields (name/characteristic/training/specialisations), and derived skill target rendering from current characteristic values + training modifier; skill edits persist through `CharacterUseCases.updateSkills` into the validated JSON-backed repository path; added tests covering skill add/edit/delete persistence, specialisations persistence, and derived target behavior after characteristic/training edits.
- **blockers:** none.

### Batch 7 recovery pass — Profile autosave actor-isolation compile fix
- **status:** validated
- **checks run:** Xcode `BuildProject`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** fixed `ProfileScreen` compile issue by invoking `ProfileAutosaveCoordinator.scheduleSave(...)` asynchronously from `.onChange` via `Task { await ... }`, preserving existing autosave behavior while satisfying actor isolation; Xcode and SwiftPM validation commands pass.
- **blockers:** none.

### Batch 8 — Notes/Talents/Traits UI depth
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** integrated Notes into accepted character detail flow with `characterID` + shared observable state; implemented editable sections for talents/traits/mutations/disorders/psychic powers/special abilities plus freeform notes; list-based notes sections support add/edit/delete and persist via `CharacterUseCases.updateNotes` through the validated JSON-backed repository path; added persistence tests for notes add/edit/delete/freeform behavior and character scoping while retaining Batch 5–7 coverage.
- **blockers:** none.

### Batch 9 — Equipment UI depth
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** integrated Equipment into the accepted character detail flow with `characterID` + shared observable state; implemented editable sections for weapons/armour/movement/inventory; weapons/armour/inventory now support add/edit/delete with editor sheets and movement fields are fully editable; edits persist through `CharacterUseCases.updateEquipment` into the validated JSON-backed repository path; added persistence tests for weapons/armour/inventory CRUD, movement edits, and character-scoped equipment updates while preserving Batch 5–8 test coverage.
- **blockers:** none.

### Batch 10 — Session mode UI depth
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** implemented Session Mode depth in accepted app flow by adding a character-scoped `SessionModeScreen` entry from character detail; session state now supports mode toggle, pinned checks add/edit/delete, and temporary modifiers add/edit/delete with editor sheets; session edits persist through `CharacterUseCases.updateSession` into the validated JSON-backed repository path via shared `CharacterListViewModel` source-of-truth; added persistence tests for session toggle, pinned check CRUD, temporary modifier CRUD, and character-scoped session edits while keeping existing Batch 5–9 coverage green.
- **blockers:** none.

### Batch 11 — Import/export user-facing UI flow
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** integrated user-facing Import/Export actions into the accepted character list flow via toolbar entry points; export now emits JSON payloads through `CharacterUseCases.exportCharacters(using:)` and the validated `CharacterJSONImportExportService`, surfaced with a platform file exporter; import now accepts JSON via platform file importer, validates schema through existing contracts, replaces persisted repository contents through `CharacterUseCases.importCharacters(from:using:)`, and refreshes shared visible list state in `CharacterListViewModel`; added tests for export envelope validity through use-cases, import restoration, unsupported schema rejection, and view-model source-of-truth refresh after import while preserving Batch 5–10 test coverage.
- **blockers:** none.

### Batch 12 — Hardening + accessibility + regressions + docs
- **status:** planned
