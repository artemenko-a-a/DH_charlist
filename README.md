# DH_charlist

Dark Heresy II character manager for iPhone/iPad.

> Current state: the project is implemented and validated on two local persistence paths:
> - JSON-backed path — validated and kept as the default/fallback path
> - SwiftData path — validated and selectable through composition/bootstrap

## Implemented and validated

The project currently includes:

- character lifecycle flow:
  - list characters
  - create (blank + template quick-start)
  - open details
  - edit profile with autosave
  - duplicate
  - delete
  - list-level search by visible profile fields (name/home world/background/role)
- character templates (local-first):
  - save any existing character as a reusable template
  - create a new character from a saved template (always new character identity)
  - template management UI: list, preview, rename, duplicate, delete
- character campaign log/history (character-scoped):
  - dedicated `Campaign Log` screen per character
  - add/edit/delete log entries with entry type, title, body, tags, timestamp
  - local filter by entry type and local search by title/body/tags
  - quick-add session note from character detail flow
  - duplicate/template-created characters start with empty history to avoid misleading carry-over
- characteristics and resources editing
- skills editing (with local in-screen search/filter)
- notes / talents / traits / mutations / disorders / psychic powers / special abilities editing (with local list-section search/filter)
- equipment editing:
  - weapons
  - armour
  - movement
  - inventory
  - local in-screen search/filter for weapons/armour/inventory
- session mode editing
- user-facing JSON import/export
- runtime host app bridge for simulator launch via `DHCharListHost`
- two validated local persistence paths:
  - JSON repository
  - SwiftData repository
  - template persistence is supported on both paths

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
## Coverage workflow (Batch 17)

Coverage source of truth is Xcode result bundles plus `xccov` output.

Canonical local coverage command:
```bash
./scripts/run_xcode_coverage.sh
```

What this command does:
- runs `xcodebuild test` with code coverage enabled for the `DHCharListHost` scheme
- writes a `.xcresult` bundle
- exports human-readable coverage summary text via `xcrun xccov view --report`
- exports machine-readable JSON coverage report via `xcrun xccov view --report --json`
- writes normalized machine metrics JSON for automation

Coverage artifact locations:
- default per-run output: `DHCharListHost/artifacts/coverage/<timestamp>/`
- latest run symlink: `DHCharListHost/artifacts/coverage/latest`
- key files:
  - `TestResults.xcresult`
  - `xcodebuild-test.log`
  - `xccov-summary.txt`
  - `xccov-report.json`
  - `coverage-metrics.json`
- override output root when needed:
```bash
COVERAGE_OUTPUT_ROOT=/absolute/path ./scripts/run_xcode_coverage.sh
```

Policy + regression check:
- baseline/policy file: `Docs/coverage-baseline.json`
- canonical local coverage gate command:
```bash
./scripts/check_coverage_policy.sh
```
- baseline refresh command (intentional/manual):
```bash
./scripts/refresh_coverage_baseline.sh
```

Current enforced policy (staged, non-vanity):
- baseline-first from real `xccov` artifacts (`coverage-metrics.json`)
- overall non-regression gate:
  - baseline: `62.50%`
  - allowed drop: `0.50pp`
- conservative per-target non-regression gate (non-test targets captured in baseline):
  - currently enforced target: `DHCharListHost.app`
  - allowed drop: `1.00pp`
- Domain/Application/Infrastructure still carry stronger testing expectations by policy intent, but strict per-layer numeric gating remains staged until layer mapping in coverage artifacts is robust.

Coverage gate failure conditions:
- `coverage-metrics.json` is missing
- baseline file is missing or baseline overall is unset
- current overall coverage drops below `baseline - allowed_overall_drop_pp`
- any enforced non-test target drops below `target_baseline - allowed_target_drop_pp`
- any enforced target disappears from current metrics or loses executable lines below policy floor

How to intentionally refresh baseline:
1. Run a new coverage capture with `./scripts/run_xcode_coverage.sh`.
2. Review `DHCharListHost/artifacts/coverage/latest/coverage-metrics.json`.
3. Run `./scripts/refresh_coverage_baseline.sh`.
4. Re-run `./scripts/check_coverage_policy.sh` to confirm the updated baseline is internally consistent.

Current environment note:
- the active `DHCharListHost` scheme reports `0` attached tests in Xcode test-plan metadata, so coverage collection from that scheme requires test action coverage to be present in the selected scheme.

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

## Batch 18 release-readiness foundation

### Host app build/archive workflow

Host app project path:
- `DHCharListHost/DHCharListHost.xcodeproj`

Host app scheme:
- `DHCharListHost` (shared)

Build from Xcode:
1. Open `DHCharListHost.xcodeproj`.
2. Select scheme `DHCharListHost`.
3. Choose an iOS simulator or a generic iOS device destination.
4. Build with `Product > Build` (or run with `Product > Run` on simulator).

Archive from Xcode:
1. Select scheme `DHCharListHost`.
2. Select destination `Any iOS Device (arm64)`.
3. Run `Product > Archive`.
4. Use Organizer to export/upload after signing is configured for your team.

Current host metadata/signing baseline:
- app bundle id: `com.example.DHCharListHost` (placeholder namespace)
- test bundle id: `com.example.DHCharListHostTests`
- display name: `DH CharList`
- deployment target: iOS 17.6 (host + tests)
- signing style: Automatic
- no personal/team-specific `DEVELOPMENT_TEAM` is committed in project settings

Assets baseline:
- AppIcon catalog includes minimal placeholder 1024x1024 light/dark/tinted assets.
- These are temporary release-readiness placeholders, not final branded assets.

### What is ready now

- Package build/test pipeline remains green.
- `DHCharListHost` project and shared scheme build in Xcode.
- Host app metadata, deployment settings, and signing structure are coherent for local development and future distribution configuration.
- Placeholder app icon structure is present to avoid archive/distribution preparation blockers caused by missing icon assets.

### What remains manual before TestFlight/App Store distribution

- Set your real Apple Developer Team in Signing & Capabilities for `DHCharListHost`.
- Replace placeholder bundle identifiers with your real production identifiers.
- Replace placeholder AppIcon assets with final branded assets meeting Apple requirements.
- Create/configure App Store Connect app record, certificates/profiles/capabilities for your account.
- Perform real device archive/export validation under your signing identity, then upload through Organizer.

## UI smoke + screenshot workflow (Batch 24)

Purpose:
- fast regression signal on key accepted flows
- reproducible screenshot capture from a deterministic seeded launch state
- not a replacement for final manual visual acceptance

Canonical UI smoke command:
```bash
./scripts/run_ui_smoke.sh
```

Canonical screenshot command:
```bash
./scripts/run_ui_screenshots.sh
```

Both commands:
- run host-scheme tests against `DHCharListHost`
- use deterministic launch flags (`-dh-uitesting -dh-ui-reset-data -dh-ui-seed-smoke -dh-ui-persistence-json`)
- write result bundles under `DHCharListHost/artifacts/`

Screenshot command additionally:
- exports attachments from the generated `.xcresult` bundle via `xcresulttool`
- writes images to `DHCharListHost/artifacts/ui-screenshots/<timestamp>/attachments`

Destination override (for either script):
```bash
UI_DESTINATION="id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C" ./scripts/run_ui_smoke.sh
UI_DESTINATION="id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C" ./scripts/run_ui_screenshots.sh
```

What UI smoke currently covers:
- app launch + character list visibility
- create blank character
- open character detail
- low-risk profile edit confirmation
- navigation entry-point coverage for characteristics/resources, skills, notes, equipment, session mode, campaign log/history
- templates manager entry point
- import/export menu entry-point visibility

What this does not guarantee:
- exhaustive branch-level feature correctness
- final visual/polish acceptance (manual checklist remains required)
