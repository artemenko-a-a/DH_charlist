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
- **status:** validated
- **checks run:** Xcode `XcodeRefreshCodeIssuesInFile` on edited screens/tests, Xcode `BuildProject`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** completed regression hardening across accepted JSON-backed flows by adding missing tests for not-found update failures, import replacement semantics, and post-import visible-state error handling in `CharacterListViewModel`; added accessibility labels/hints and VoiceOver-friendly combined summaries on major implemented UI surfaces (character list/detail, profile, characteristics/resources, skills, notes, equipment, session mode) without architecture or feature-scope expansion; refreshed `README.md` and `Docs/manual-smoke-checklist.md` to match current implemented/validated scope and runtime limits.
- **blockers:** none for the historical Batch 12 code pass itself; at that time SwiftData runtime validation and simulator/UI runtime smoke had not yet been completed in this environment.
### Revalidation sweep — Batch 3 / Batch 4 / Batch 5 (post-Batch-12 state)
- **Batch 3 status:** blocked
- **Batch 3 checks run:** Xcode `BuildProject`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **Batch 3 results:** availability-gated `SwiftDataCharacterRepository` still compiles in current codebase as a placeholder adapter behind `#if canImport(SwiftData)`; no runtime SwiftData execution path was validated in this environment.
- **Batch 3 blockers:** SwiftData runtime validation remains unavailable here, so Batch 3 cannot be marked validated.
- **Batch 4 status:** validated
- **Batch 4 checks run:** Xcode `BuildProject`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **Batch 4 results:** app host/app shell, tab flow foundation, and `AppContainer` composition-root wiring compile and remain intact after later batches; no regression observed from subsequent UI integrations.
- **Batch 4 blockers:** none.
- **Batch 5 status:** validated
- **Batch 5 checks run:** Xcode `BuildProject`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **Batch 5 results:** character lifecycle slice remains valid on current branch (list load, create, open details, profile autosave edit path, duplicate, delete, and overview/state persistence behavior) with existing tests passing and no regression fix required.
- **Batch 5 blockers:** none.

### Batch 13 — Minimal iOS host-app readiness (package-to-simulator bridge)
- **status:** validated
- **checks run:** repository structure inspection via Xcode project navigator tools, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, simulator launch/manual run via `DHCharListHost`
- **results:** host-app bridge is now complete: a minimal iOS host app target/project was created, linked to the local `DHCharList` package, configured to launch the accepted package UI, and successfully builds and launches in simulator.
- **blockers:** none.

### Batch 14 — Real SwiftData persistence adapter + composition selection
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, Xcode `ExecuteSnippet` in `DHCharListHostApp.swift` using `.live(persistence: .swiftData)`
- **results:** replaced placeholder with a working `SwiftDataCharacterRepository` supporting `fetchAll`, `fetch(id:)`, `save(_)`, and `delete(id:)`; implemented explicit domain-to-persistence mapping using a conservative SwiftData record (`id`, `updatedAt`, serialized character payload) to persist and restore accepted nested scope (`profile`, `characteristics/resources`, `skills`, `notes`, `equipment`, `session`); added composition-level persistence selection in `AppContainer.live(persistence:)` while preserving JSON default and automatic fallback to JSON if SwiftData initialization is unavailable; added SwiftData repository CRUD/isolation/parity tests against the accepted JSON-backed behavior; host runtime snippet confirmed SwiftData path persisted and listed data (`swiftdata_runtime_probe_count 1`, first name `Runtime Probe`).
- **blockers:** none for Batch 14 implementation/validation in this environment.
- **Batch 3 reclassification:** Batch 3 moves from **blocked** to **validated** based on real adapter implementation plus runtime-backed SwiftData validation in this environment.

### Batch 13 — Runtime polish, accessibility, and simulator-smoke hardening (JSON-backed path)
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`
- **results:** applied runtime polish in accepted JSON-backed flows without feature-scope expansion: list/import/export/edit operations now clear stale error state after successful actions; error alert presentation uses a stable dismissable binding; character detail missing-state screen now includes an explicit `Back to Characters` action to avoid navigation dead-ends; added regression test `importSuccessClearsPreviousViewModelError`; refreshed manual smoke checklist with runtime coherence, accessibility, and Dynamic Type verification steps.
- **blockers:** no code-level blockers; simulator interaction checks remain manual checklist execution.

### Current canonical batch status summary
- Batch 3 — validated
- Batch 4 — validated
- Batch 5 — validated
- Batch 6 — validated
- Batch 7 — validated
- Batch 8 — validated
- Batch 9 — validated
- Batch 10 — validated
- Batch 11 — validated
- Batch 12 — validated
- Batch 13 (host-app readiness) — validated
- Batch 13 (runtime polish/accessibility) — validated
- Batch 14 (real SwiftData adapter) — validated
- Batch 15 (runtime UX polish + iPad refinement) — validated
- Batch 16 (coverage pipeline, reporting, and policy) — validated

### Batch 15 — Runtime UX polish + iPad refinement
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, `xcrun simctl list devices available`
- **results:** completed focused polish pass on existing accepted flows only: improved empty-state and inline guidance copy across character detail/features; added safer destructive confirmation for character delete; tightened row rendering for long/empty values; added practical accessibility hints/labels and Dynamic Type-friendly multiline behavior on major list/form/detail surfaces; standardized sheet presentation behavior for existing editors; applied iPad-oriented content width refinement to major list/form screens without changing navigation architecture; preserved accepted JSON-default + SwiftData-alternative behavior and current composition root patterns; added regression tests `exportSuccessClearsPreviousViewModelError` and `deleteSuccessClearsPreviousViewModelError`.
- **blockers:** simulator runtime sanity execution was not available in this environment because `CoreSimulatorService` was unavailable (`Connection invalid/refused`), so manual runtime checklist execution remains required outside this run.

### Batch 16 — Coverage pipeline, reporting, and policy
- **status:** validated
- **checks run:** Xcode `BuildProject`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, local `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C' -enableCodeCoverage YES -resultBundlePath /tmp/DHCharListCoverage.xcresult`, `./scripts/run_xcode_coverage.sh`, `./scripts/check_coverage_policy.sh`
- **results:** repository-local coverage pipeline is now validated end-to-end on the local machine: host-scheme Xcode test execution runs successfully with code coverage enabled, produces a real `.xcresult` bundle, and the repository scripts generate xccov text summary, JSON report, and machine metrics JSON artifacts. Coverage baseline/reporting workflow is now operational for local development.
- **blockers:** none for the local development workflow; Codex/Xcode sandbox limitations remain environment-specific and do not block repository validation.

### Batch 17 — CI-oriented coverage gate + baseline enforcement
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `./scripts/run_xcode_coverage.sh`, `./scripts/check_coverage_policy.sh`, `COVERAGE_POLICY_PATH=/tmp/coverage-baseline-batch17.json ./scripts/refresh_coverage_baseline.sh`
- **results:** implemented practical baseline-first gate from validated local coverage artifacts: `check_coverage_policy.sh` now enforces overall non-regression (`0.5pp` budget from frozen baseline) plus conservative non-test target non-regression (`1.0pp` budget) for baseline-tracked targets; added explicit baseline refresh tooling via `scripts/refresh_coverage_baseline.sh`; froze measured baseline in `Docs/coverage-baseline.json` from the accepted local `latest/coverage-metrics.json`; updated documentation with canonical run/gate commands, artifact paths, fail conditions, and staged policy maturity.
- **blockers:** no repository/product blockers; direct shell writes to repo-root docs can be sandbox-restricted in this Codex environment, so baseline-refresh validation used an alternate writable policy path in `/tmp` for command-level verification.

# Current canonical blocker summary
- There are no active product or coverage blockers in the current local development workflow.
- The accepted app/runtime/persistence paths remain validated.
- Coverage execution is validated locally through `DHCharListHost` and `./scripts/run_xcode_coverage.sh`.
- Codex/Xcode sandbox limitations remain an environment-specific limitation, not a repository blocker.

### Current canonical runtime / coverage summary
- Host app bridge exists and launches in simulator via `DHCharListHost`.
- JSON-backed path is validated and remains the default/fallback local persistence path.
- SwiftData path is validated and available through composition/bootstrap selection.
- Xcode-native code coverage execution is validated locally through the host scheme and `./scripts/run_xcode_coverage.sh`.
- The remaining Codex/Xcode sandbox limitations are environment-specific and do not block local repository validation.

## 2026-03-08

### Batch 18 — Release-readiness foundation (host metadata/packaging/assets/signing/docs)
- **status:** validated with documented manual distribution follow-up
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, attempted `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/DHCharListHost-Batch18.xcarchive CODE_SIGNING_ALLOWED=NO archive`
- **results:** host app metadata/settings were normalized for release-readiness without scope expansion: removed committed personal `DEVELOPMENT_TEAM` values, set coherent placeholder bundle identifiers (`com.example.DHCharListHost` / `com.example.DHCharListHostTests`), added generated display name (`DH CharList`), and kept deployment/signing defaults internally consistent; app icon catalog now includes minimal placeholder 1024x1024 light/dark/tinted assets plus mapped filenames for clean host target setup; scheme/build actions remain archive-capable and Xcode host build succeeds.
- **blockers:** archive/distribution command-level validation is partially blocked in this environment by sandbox restrictions to Xcode/Simulator/DerivedData cache paths (CoreSimulatorService + cache/log write permissions), so real signed archive/export/TestFlight upload remains a manual step on a normal local Xcode environment.

### Batch 19 — Search + usability upgrades (existing validated flows only)
- **status:** validated with manual runtime pass pending
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, attempted `xcrun simctl list devices available`
- **results:** implemented scoped day-to-day usability improvements without architecture/persistence scope changes: added character-list search/filter on visible profile fields (name/home world/background/role) with result counts and clear no-match state; added in-screen search/filter on Skills (including characteristic/training/specialisations matching) and on Notes list sections (talents/traits/mutations/disorders/psychic powers/special abilities) with safe filtered edit/delete index mapping; added in-screen search/filter for Equipment weapons/armour/inventory with safe filtered deletion mapping; added quick-add toolbar menus for Notes and Equipment; improved character detail section entry points with clearer labeled navigation rows; preserved accepted JSON-default + SwiftData-alternative behavior and existing create/open/edit/duplicate/delete/import/export/session flows; added regression tests for new search/filter helpers and filtered-state behavior.
- **blockers:** real simulator runtime smoke could not be executed in this environment because CoreSimulatorService is unavailable (`Connection invalid/refused`); manual runtime pass remains required on a normal local simulator environment.

### Batch 20 — Adeptus Mechanicus visual theme foundation
- **status:** validated for build/test; manual runtime visual pass pending
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, attempted `xcrun simctl list devices available`
- **results:** introduced a centralized reusable presentation theme layer in `Presentation/Theme/CogitatorTheme.swift` with restrained industrial palette tokens (graphite/steel, mars-red, brass, amber), reusable section-header styling, reusable status-chip styling (nominal/caution/warning/critical), and shared screen/panel modifiers for consistent list/form chrome. Applied themed surfaces to high-visibility existing flows without changing behavior: character detail/overview + subsystem links, characteristics/resources editing surface, session mode surface + session editor sheets, equipment surface + editor sheets. Added light-touch thematic subtitle/microcopy in section headers while preserving clear-first navigation/labels and existing interaction patterns. Dynamic Type-safe text/layout behavior and accepted runtime/persistence flows remain unchanged.
- **blockers:** simulator/runtime visual verification remains blocked in this environment because `CoreSimulatorService` is unavailable (`Connection invalid/refused`), so focused manual visual review must be completed in a normal local simulator/device environment.

### Batch 20 — Corrective pass (contrast/readability/hierarchy hardening)
- **status:** validated for build/test; focused runtime visual pass pending
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, attempted `xcrun simctl list devices available`
- **results:** performed a scoped corrective pass on the existing Batch 20 theme foundation without behavior changes: tuned shared cogitator tokens for stronger legibility (`textPrimary/textSecondary/textTertiary`, brighter brass/amber accents, improved panel/background separation, stronger panel edge/separator contrast), strengthened section header visual hierarchy (larger/bolder title + clearer subtitle), and improved empty-state readability via reusable themed empty-state styling. Applied hierarchy/readability corrections on the themed major screens only (character list, character detail/overview, characteristics/resources, session mode, equipment): clearer row title/summary contrast, clearer footer guidance contrast, and stronger section header/readability separation while preserving the industrial Adeptus Mechanicus slate direction.
- **blockers:** simulator/runtime visual verification remains blocked in this environment because `CoreSimulatorService` is unavailable (`Connection invalid/refused`), so the focused manual visual sanity pass on character list/detail/session must be run on a normal local simulator/device environment.
