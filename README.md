# DH_charlist

Dark Heresy II character manager (iPhone/iPad-first scope) implemented as a Swift Package.

## Current validated state (through Batch 14)
- Domain layer and use-cases are implemented and tested (domain remains independent of SwiftUI/SwiftData).
- JSON-backed local persistence path is implemented and validated:
  - `JSONFileCharacterRepository`
  - `CharacterJSONImportExportService`
- SwiftData local persistence adapter is implemented and runtime-validated in this environment:
  - `SwiftDataCharacterRepository` supports `fetchAll`, `fetch(id:)`, `save(_)`, `delete(id:)`
  - composition selects backend via `AppContainer.live(persistence:)`
  - JSON remains the default backend; SwiftData is opt-in
- App composition root is preserved (`AppContainer`) and presentation does not construct infrastructure directly.
- Accepted user flows implemented on the JSON path:
  - character lifecycle (list/create/open/edit profile autosave/duplicate/delete)
  - characteristics/resources editing
  - skills CRUD + derived target display
  - notes sections CRUD + freeform notes
  - equipment CRUD (weapons/armour/inventory) + movement edits
  - session mode toggle + pinned checks + temporary modifiers
  - import/export UI flow with repository replacement semantics on import
- Batch 12 hardening completed:
  - regression-focused coverage added for missing gaps
  - accessibility labels/hints and VoiceOver row summaries added on major UI surfaces
  - docs updated to match implemented and validated truth
- Batch 13 runtime polish completed on accepted JSON-backed flow:
  - safer error lifecycle in list/import/export/editing flow (stale error cleared after successful operations)
  - character-detail missing-state now includes explicit return action to avoid dead-end navigation
  - manual smoke checklist expanded for accessibility/dynamic-type/runtime coherence verification

## Validation commands used
```bash
swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
```

## Run on iOS simulator
The package already exposes a host-compatible SwiftUI entry type: `DHCharListIOSAppHost`.
It launches the accepted shell using the same composition root path (`DHCharListAppShell(container: .live())`).

Minimal manual Xcode step still required (package-only repo has no committed app target):
1. In Xcode, create an iOS App target/project and add local package dependency `DH_charlist` (`/Users/an.artemenko/repos/DH_charlist`).
2. In the app target entry file, use the package host app:

```swift
import SwiftUI
import DHCharList

@main
struct DHCharListHostApp: App {
    var body: some Scene {
        WindowGroup {
            DHCharListAppShell(container: .live())
        }
    }
}
```

After this step, run that app scheme on an iOS Simulator.

To opt into SwiftData backend for host validation, switch composition to:

```swift
DHCharListAppShell(container: .live(persistence: .swiftData))
```

## Runtime blockers
- Full simulator/UI runtime smoke execution is not validated in this environment.

See [Docs/manual-smoke-checklist.md](/Users/an.artemenko/repos/DH_charlist/Docs/manual-smoke-checklist.md) for the exact human-run simulator checks.
