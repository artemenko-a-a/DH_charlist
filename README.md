# DH_charlist

Dark Heresy II character manager for iPhone/iPad.

## Web app

The repository now also contains a local-first web application in `web/`.

Run it locally:

```bash
cd web
npm install
npm run dev
```

Validated web commands:

```bash
cd web
npm run typecheck
npm run test
npm run build
```

Current web scope:
- character roster create/select/duplicate/delete
- profile, characteristics/resources, skills, notes, equipment, and inventory editing
- session workspace with bounded quick mechanics, attack/reaction shortcuts, and bounded damage helper
- XP validation/apply with explainable prerequisite checks
- weapon and armour compendium autocomplete/import with detached-copy and replace-all confirmation semantics
- dossier preview with browser print/share

Current validation caveat:
- web validation is green locally
- `make typecheck` and `make test` are green locally
- host-project Xcode validation on this machine is currently blocked because the local Xcode installation is missing the iOS 26.4 platform/component needed by `DHCharListHost`

> Current state: the project is implemented and validated on two local persistence paths:
> - JSON-backed path — validated and kept as the default/fallback path
> - SwiftData path — validated and selectable through composition/bootstrap, with explicit fallback diagnostics when JSON remains active

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
  - local weapon compendium autocomplete from a bounded safe catalog
  - adding from the compendium creates a detached editable character-owned weapon copy
  - armour
  - local armour compendium autocomplete from a bounded safe catalog
  - adding from the compendium creates a detached editable character-owned armour copy
  - movement
  - inventory
  - local in-screen search/filter for weapons/armour/inventory
- session mode / combat workspace editing
- quick mechanics helpers:
  - characteristic-based quick checks
  - skill-based quick checks
  - standard modifiers (`+30` to `-30`) plus custom signed modifier entry
  - session-mode quick access with temporary modifier reuse
- user-facing JSON import/export with replace-all preview and destructive confirmation
- single-character dossier export:
  - open from character detail
  - preview a readable structured dossier in-app
  - share/save/print a generated PDF through the native iOS share sheet
- runtime host app bridge for simulator launch via `DHCharListHost`
- two validated local persistence paths:
  - JSON repository
  - SwiftData repository
  - template persistence is supported on both paths
  - current backend status is visible from the `Characters` import/export menu via `Persistence Status`
  - if requested `SwiftData` falls back to JSON, the app shows a persistence notice instead of hiding the fallback

## Persistence modes

### Default / fallback
The default local persistence path is JSON-backed.

### SwiftData
SwiftData is also implemented and validated and can be selected through composition:

- `AppContainer.live(persistence: .swiftData)`

The JSON-backed path remains available as the conservative fallback.

### Persistence diagnostics (Batch 32)

The app now exposes the actual bootstrap result instead of silently masking fallback:

- requested backend
- active backend
- whether fallback occurred
- fallback diagnostic note when available

Where to check it:
- `Characters` -> `Import/Export` -> `Persistence Status`

Current behavior:
- requesting `SwiftData` still falls back to JSON when bootstrap cannot complete
- fallback keeps the app usable
- fallback is surfaced explicitly in diagnostics, and the `Characters` screen shows a notice when JSON is active instead of requested `SwiftData`

## Quick mechanics helpers (Batch 29)

Quick mechanics is a transparent in-session target builder. It uses existing character data plus explicit modifiers only; it does not roll dice and does not persist results automatically.

Developer note:
- current mechanics-check calculation logic lives in `Sources/DHCharList/Rules/MechanicsChecks.swift`
- the helper now resolves through one unified `MechanicsCheckResolver` path over explicit `CheckDefinition`, `CheckRequest`, `CheckResult`, `RuleBreakdown`, `RuleContribution`, `CheckModifier`, and `RuleCondition` models
- current session/combat helper entry points now also normalize accepted active-weapon, combat-condition, pinned-check, and temporary-modifier state into explicit `CombatContext`, `ActiveWeaponContext`, and `CombatCheckPreparationContext` models before invoking the rules layer
- stable mechanics metadata now comes from bounded typed registries in `Sources/DHCharList/Rules/RulesRegistries.swift`, including difficulty presets, canonical skill metadata, weapon type/trait metadata, and condition metadata with safe ad hoc fallback for unknown/custom values
- a separate bounded damage foundation now lives in `Sources/DHCharList/Rules/DamagePipeline.swift` with explicit request/result/breakdown modeling for raw damage, mitigation, and wound application; it is a rules-layer foundation, not a user-facing combat simulator
- deterministic golden/scenario regression protection for the accepted rules foundation now lives in `Tests/DHCharListTests/RulesGoldenScenarioTests.swift`, locking explainable check outputs, combat-context-backed preparation, and bounded damage outcomes through explicit table-driven expectations
- this is a foundation for future rules work, not a full rules engine

Where to open it:
- `Characteristics & Resources` via the scope button on a characteristic row
- `Skills` via the quick-check button on a skill row
- `Session Mode` via `Open Quick Mechanics`

What it shows:
- check name
- source characteristic or skill
- base value
- derived bonus
- skill training contribution when relevant
- applied modifier
- final target
- a stable ordered rules breakdown behind those readouts

Current helper behavior:
- standard presets: `+30`, `+20`, `+10`, `+0`, `-10`, `-20`, `-30`
- custom signed modifier input is supported
- modifiers now resolve through normalized structured inputs with bounded kind/scope instead of ad hoc numbers/labels
- current Session Mode temporary modifiers can be reused directly in the helper when present
- current Session Mode combat conditions now appear as explicit helper context, but they are not auto-translated into numeric rule effects yet
- on compact sheet sizes, scroll within the helper to reach the full breakdown and final target rows

## Import behavior (Batch 31)

JSON import remains a roster-level replace-all operation.

Before import is applied, the app now shows:
- how many characters were detected in the imported payload
- that the operation replaces the current local roster and does not merge
- that characters missing from the imported file will be removed
- that the action is destructive

Current safety boundary:
- cancel is the safe default
- import is not currently undoable from the app
- backup/snapshot before import is intentionally deferred for now

## Character dossier export (Batch 35)

The app now supports a single-character dossier flow for printing or sharing without turning export into a publishing subsystem.

Where to open it:
- open any character
- tap `Dossier` in the character detail toolbar

What it does:
- shows an in-app readable dossier preview with document-style layout
- structures existing accepted data into practical sections:
  - identity / profile
  - characteristics / resources
  - skills
  - notes / abilities
  - equipment
  - session snapshot
  - recent history summary when present
- prepares a printable PDF from the current character state
- uses the native iOS share sheet for share / Save to Files / print destinations

Current scope limits:
- single character only
- no roster batch export
- no cloud sharing
- no editable PDF form mode

## Local equipment compendium flows (Batches 43-46)

The `Equipment` flow now supports bounded local compendium assistance for both weapons and armour. Both compendiums support a local JSON replace-all import path.

Weapon flow:
- open a character
- open `Equipment`
- choose `Add Weapon`
- search the local compendium by weapon name and tap a matching entry
- use `Import Local Compendium` to replace the current local weapon catalog from a structured JSON file

Weapon behavior:
- the editor prefills key weapon fields from the selected catalog definition
- saving creates a detached character-owned weapon copy
- later edits affect only the character weapon instance, not the source definition
- JSON compendium import replaces the current local weapon compendium with explicit destructive confirmation
- imported catalog entries power future autocomplete/add-weapon flows only
- existing character-owned weapons remain detached and unchanged after compendium replacement
- schema details for local weapon import are documented in `Docs/weapon-compendium-format.md`

Armour flow:
- open a character
- open `Equipment`
- choose `Add Armour`
- search the local compendium by armour name and tap a matching entry
- use `Import Local Armour Compendium` to replace the current local armour catalog from a structured JSON file

Armour behavior:
- the editor prefills location and armour points from the selected catalog definition
- saving creates a detached character-owned armour copy
- the copied armour stays plain character-owned data; there is no persistent source link back to the compendium definition
- the accepted manual armour editor remains the place to adjust values before saving
- JSON compendium import replaces the current local armour compendium with explicit destructive confirmation
- imported catalog entries power future autocomplete/add-armour flows only
- existing character-owned armour remains detached and unchanged after compendium replacement
- schema details for local armour import are documented in `Docs/armour-compendium-format.md`

Current scope limits:
- the built-in weapon and armour catalogs are bounded safe local demo catalogs, not full rulebook datasets
- local import uses JSON schema v1 replace-all semantics for both weapons and armour
- compendium import is replace-all only; there is no merge/conflict UI
- no OCR or rulebook parsing
- no cloud compendium
- no persistent source link after insertion
- no embedded copyrighted full-rulebook dataset is committed

## Combat workspace (Batch 30)

`Session Mode` now acts as a practical combat workspace over the accepted character/session data. It keeps state explicit and local-first; it does not add automated combat resolution.

What it surfaces:
- quick-adjust current wounds, fatigue, and current fate
- active weapon selection from existing weapon entries plus a compact live-play summary
- movement values from existing equipment data
- pinned checks and temporary modifiers in the same workspace
- short combat condition/status notes
- one-tap quick mechanics shortcuts for common combat-facing checks
- encounter shortcuts for attack, dodge, parry, reload, and bounded damage application
- quick toggles for common combat modifiers and conditions during active play

Current workspace behavior:
- active weapon selection persists as session-scoped state and clears safely if the referenced weapon is removed later
- combat conditions are lightweight user-managed notes, not a rules-driven status engine
- quick mechanics access from `Session Mode` remains transparent and uses the same modifier breakdown as Batch 29
- guided attack flow stays bounded and manual-first: confirm weapon/context, apply modifiers, enter roll, then optionally route raw damage through the accepted damage pipeline
- dodge and parry shortcuts reuse the same explainable check engine rather than a separate combat-only path
- reload and quick-toggle actions are explicit conveniences only; there is still no action-economy enforcement or full combat simulation
- iPhone layouts prioritize the combat summary and shortcuts first, while keeping the full workspace usable on iPad

## XP progression validation (Batches 48-49)

The app now includes a bounded XP-spend and prerequisite-validation foundation rather than a full progression builder.

Where to open it:
- open a character
- open `Characteristics & Resources`
- use the `Spend XP` action in the `Advancement` section

What it supports today:
- characteristic advances
- existing skill training advances
- bounded talent and advance catalog registries for progression metadata, cost defaults, and prerequisite metadata
- explicit manual XP cost entry
- explainable prerequisite checks for:
  - available XP
  - minimum characteristic
  - required skill training
  - required aptitude
  - required talent
  - required trait

What it shows:
- upgrade summary
- XP cost
- currently available XP
- projected remaining XP
- which prerequisites passed or failed
- clear validation errors when a spend is not allowed

Current apply behavior:
- applying a valid spend updates the character through the accepted save path
- XP is deducted by increasing `experienceSpent`
- a concise `advancement` history entry is recorded for the character

Current registry boundary:
- the current `Spend XP` screen remains intentionally small and still exposes bounded characteristic/skill spends only
- registry-backed metadata now lives in `Sources/DHCharList/Rules/ProgressionRegistries.swift`
- bounded talent unlock support now exists in the rules/progression layer for future progression UX work, but this batch does not add a full talent-tree or builder UI

Current scope limits:
- no full character builder
- no giant prerequisite DSL
- no talent-tree engine
- no respec/rebuild flow
- no campaign economy manager

## How to run tests

```bash
swift test
```

How to build the package:
```bash
swift build
```

Repository task runner:
```bash
make fmt
make lint
make typecheck
make test
make ci
```

Current fallback note:
- `fmt` and `lint` are documented no-op fallbacks in this repo because no dedicated formatter/linter configuration is committed yet
- `typecheck`, `test`, and `ci` run the canonical SwiftPM/Xcode validation commands

## Coverage workflow (Batch 33)

Coverage gating is now based on the real package source surface in `Sources/DHCharList`.

Source of truth:
- gate enforcement: SwiftPM code coverage JSON produced from `swift test --enable-code-coverage`
- host diagnostics: Xcode result bundle plus `xcrun xccov` output from the `DHCharListHost` scheme

Canonical local coverage command:
```bash
./scripts/run_xcode_coverage.sh
```

What this command does:
- runs `xcodebuild test` with code coverage enabled for the `DHCharListHost` scheme
- runs `swift test --enable-code-coverage` for the package
- writes a `.xcresult` bundle
- exports human-readable coverage summary text via `xcrun xccov view --report`
- exports machine-readable JSON coverage report via `xcrun xccov view --report --json`
- captures SwiftPM code coverage JSON for `Sources/DHCharList`
- writes normalized machine metrics JSON for automation and policy checks

Coverage artifact locations:
- default per-run output: `DHCharListHost/artifacts/coverage/<timestamp>/`
- latest run symlink: `DHCharListHost/artifacts/coverage/latest`
- key files:
  - `TestResults.xcresult`
  - `xcodebuild-test.log`
  - `xccov-summary.txt`
  - `xccov-report.json`
  - `swiftpm-test.log`
  - `swiftpm-codecov.json`
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
- baseline-first from real package coverage artifacts in `coverage-metrics.json`
- `package_surface` must be present; host-only/test-only artifacts are rejected
- all baseline package files must still appear in current metrics
- overall package non-regression is enforced with a `0.50pp` budget from the measured baseline
- per-area non-regression is enforced for the top-level package areas tracked by the current baseline (currently `App`, `Application`, `Domain`, `Infrastructure`, `Presentation`, `Rules`) with a `1.00pp` budget
- host `xccov` metrics are still captured, but they are diagnostics only and are not enough on their own to produce a green gate

Coverage gate failure conditions:
- `coverage-metrics.json` is missing
- `package_surface` is missing or too small to be truthful
- baseline package file coverage surface disappears from current metrics
- current package coverage drops below `baseline - allowed_package_drop_pp`
- any enforced package area drops below `area_baseline - allowed_area_drop_pp`
- a baseline-tracked package area disappears or falls below the executable-line floor

What the gate now guarantees:
- green means `Sources/DHCharList` was actually measured in the current coverage capture
- green means the measured package surface did not regress beyond the allowed package/area budgets

What the gate still does not guarantee:
- it is not diff coverage or touched-file coverage
- it does not prove strong UI coverage for large SwiftUI presentation files
- it does not replace runtime smoke checks or focused UI tests

How to intentionally refresh baseline:
1. Run a new coverage capture with `./scripts/run_xcode_coverage.sh`.
2. Review `DHCharListHost/artifacts/coverage/latest/coverage-metrics.json`.
3. Run `./scripts/refresh_coverage_baseline.sh`.
4. Re-run `./scripts/check_coverage_policy.sh` to confirm the updated baseline is internally consistent.

How to run in simulator

Open DHCharListHost.xcodeproj in Xcode, choose the DHCharListHost scheme, select an iOS simulator, and run the app.

The host app launches the accepted package UI and is the intended simulator/runtime entry point.

Current architectural state
    •    Domain remains independent from SwiftUI and SwiftData.
    •    Presentation does not construct infrastructure directly.
    •    Composition/bootstrap chooses the persistence implementation.
    •    JSON-backed path is the default validated runtime-safe path.
    •    SwiftData path is implemented as a validated alternative.
    •    Current mechanics checks, bounded damage primitives, and bounded XP/progression validation live in a dedicated `Rules` layer and resolve through explicit request/result/breakdown models, normalized modifier/condition inputs, bounded typed rules registries for stable metadata, a combat-context adapter for the accepted Session Mode / combat workspace flows, explicit XP spend/prerequisite models, and bounded progression registries for talents plus characteristic/skill advances.

Notes

This repository was delivered in controlled batches with validation and recovery passes.
Historical delivery details and batch-by-batch status are tracked in:
    •    Docs/progress-log.md
    •    Docs/decision-log.md
    •    Docs/rules-engine-roadmap.md
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
- Batch 28 validated a real unsigned device archive path for `DHCharListHost`:
  - `xcodebuild ... -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`
  - `xcodebuild ... -configuration Release -destination 'generic/platform=iOS' archive CODE_SIGNING_ALLOWED=NO`
- Batch 28 also probed export behavior from that archive and confirmed the real remaining boundary:
  - `xcodebuild -exportArchive ...` fails with `No Team Found in Archive` until a real Apple team/signing context is configured.

### What remains manual before TestFlight/App Store distribution

- Set your real Apple Developer Team in Signing & Capabilities for `DHCharListHost`.
- Replace placeholder bundle identifiers with your real production identifiers.
- Replace placeholder AppIcon assets with final branded assets meeting Apple requirements.
- Create/configure App Store Connect app record, certificates/profiles/capabilities for your account.
- Perform real device archive/export validation under your signing identity, then upload through Organizer.

Batch 28 distribution/TestFlight notes:
- current committed app bundle id remains `com.example.DHCharListHost`
- current committed marketing/build versions remain `1.0` / `1`
- the repository is now truthfully `archive-ready` and `TestFlight-prepared`, not fully TestFlight-ready without Apple-account-controlled signing
- exact manual steps and command examples are documented in `Docs/testflight-distribution.md`

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

GitHub-hosted manual workflow note:
- `.github/workflows/ui-tests.yml` is now live on GitHub-hosted runners
- the workflow stays optional/manual (`workflow_dispatch`)
- hosted assumptions are explicit:
  - runner label: `macos-15`
  - Xcode path: `/Applications/Xcode_16.4.app/Contents/Developer`
  - simulator selection: first available iPhone simulator on the runner
  - simulator readiness gate: `xcrun simctl bootstatus <udid> -b` before invoking the canonical UI scripts
- live hosted validation for Batch 27:
  - smoke mode completed green in GitHub Actions
  - screenshot mode completed green in GitHub Actions and uploaded exported PNG attachments

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

## CI workflow (Batch 25)

Repository workflows:
- `.github/workflows/ci.yml` (push + pull_request)
- `.github/workflows/ui-tests.yml` (`workflow_dispatch`, manual)

What runs on every push/PR (`ci.yml`):
- `Fast validation (SwiftPM)`:
  - `swift build`
  - `swift test`
- `Xcode host + coverage gate`:
  - host app build (`xcodebuild ... build`)
  - `./scripts/run_xcode_coverage.sh`
  - `./scripts/check_coverage_policy.sh`

What is optional/heavier:
- `UI Tests (manual)` workflow:
  - smoke path: `./scripts/run_ui_smoke.sh`
  - screenshots path: `./scripts/run_ui_screenshots.sh`
  - hosted workflow assumptions:
    - `macos-15`
    - `DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer`
    - first available iPhone simulator, with `bootstatus -b` wait before test execution

CI artifacts:
- `coverage-artifacts` (from required `ci.yml` job):
  - `TestResults.xcresult`
  - `xcodebuild-test.log`
  - `xccov-summary.txt`
  - `xccov-report.json`
  - `swiftpm-test.log`
  - `swiftpm-codecov.json`
  - `coverage-metrics.json`
- `ui-smoke-artifacts` (manual workflow, smoke mode)
- `ui-screenshot-artifacts` (manual workflow, screenshots mode; includes exported attachments)

Local-to-CI command mapping:
- local `swift build` -> CI `Fast validation (SwiftPM)`
- local `swift test` -> CI `Fast validation (SwiftPM)`
- local `./scripts/run_xcode_coverage.sh` -> CI `Xcode host + coverage gate`
- local `./scripts/check_coverage_policy.sh` -> CI `Xcode host + coverage gate`
- local `./scripts/run_ui_smoke.sh` -> manual `UI Tests (manual)` with `test_target=smoke`
- local `./scripts/run_ui_screenshots.sh` -> manual `UI Tests (manual)` with `test_target=screenshots`

Intentionally manual:
- screenshot capture/review remains manual-triggered because it is heavier and artifact-oriented
- final visual acceptance stays on the manual checklist (`Docs/manual-smoke-checklist.md`)

## Web app (experimental, local-first)

A repo-integrated web target now exists under `web/`.

Run:
- `cd web`
- `npm install`
- `npm run dev`

Validation:
- `npm run typecheck`
- `npm run test`
- `npm run build`

Current web scope is a bounded but genuinely usable local-first companion app:
- character roster create/select/duplicate/delete
- profile, characteristics/resources, skills, notes, and equipment editing
- session workspace with quick checks, active weapon state, temporary modifiers, pinned checks, combat conditions, bounded attack/reaction helpers, and bounded damage helper
- XP validation/apply flow for characteristic advances, skill advances, and bounded talent unlocks
- weapon and armour compendium autocomplete/add/import with explicit replace-all confirmation and detached-copy semantics
- browser dossier preview with print/share support

The web app still does not claim full iOS parity or full rules-engine coverage. Final repo-wide host-project Xcode validation on this machine is currently blocked by a missing local iOS 26.4 platform install; see `.agent/tasks/2026-03-web-final-acceptance/`.
