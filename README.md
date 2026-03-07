# DH_charlist

Dark Heresy II character manager for iPhone/iPad.

> Current state: the project is implemented and validated on two local persistence paths:
> - JSON-backed path — validated and kept as the default/fallback path
> - SwiftData path — validated and selectable through composition/bootstrap

## Implemented and validated

The project currently includes:

- character lifecycle flow:
  - list characters
  - create
  - open details
  - edit profile with autosave
  - duplicate
  - delete
- characteristics and resources editing
- skills editing
- notes / talents / traits / mutations / disorders / psychic powers / special abilities editing
- equipment editing:
  - weapons
  - armour
  - movement
  - inventory
- session mode editing
- user-facing JSON import/export
- runtime host app bridge for simulator launch via `DHCharListHost`
- two validated local persistence paths:
  - JSON repository
  - SwiftData repository

## Persistence modes

### Default / fallback
The default local persistence path is JSON-backed.

### SwiftData
SwiftData is also implemented and validated and can be selected through composition:

- `AppContainer.live(persistence: .swiftData)`

The JSON-backed path remains available as the conservative fallback.

## How to run tests

```bash
swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
```
How to build the package
```bash
swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
```
How to run in simulator

Open DHCharListHost.xcodeproj in Xcode, choose the DHCharListHost scheme, select an iOS simulator, and run the app.

The host app launches the accepted package UI and is the intended simulator/runtime entry point.

Current architectural state
    •    Domain remains independent from SwiftUI and SwiftData.
    •    Presentation does not construct infrastructure directly.
    •    Composition/bootstrap chooses the persistence implementation.
    •    JSON-backed path is the default validated runtime-safe path.
    •    SwiftData path is implemented as a validated alternative.

Notes

This repository was delivered in controlled batches with validation and recovery passes.
Historical delivery details and batch-by-batch status are tracked in:
    •    Docs/progress-log.md
    •    Docs/decision-log.md
    •    Docs/manual-smoke-checklist.md

