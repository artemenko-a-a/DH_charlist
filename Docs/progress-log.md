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

### Batch 21 — Deep runtime polish pass (consistency + interaction coherence)
- **status:** validated for build/test; focused runtime manual acceptance pass pending
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, attempted `xcrun simctl list devices available`
- **results:** completed a scope-limited deep polish pass across existing accepted screens and editor flows with no runtime/persistence behavior changes. Added shared rhythm primitives in theme (`defaultMinListRowHeight`, iOS section spacing, helper text style, consistent panel insets) and applied them broadly to character list/detail, profile, characteristics/resources, skills, notes, equipment, and session mode. Refined text hierarchy for row titles/summaries/footer guidance, normalized section spacing and panel rhythm, and improved iPad readability through wider-but-bounded content width logic in `formContentWidth`. Polished existing editor sheets for skills/notes/equipment/session with consistent themed form rhythm, clearer sectioned headers, and consistent Save-action emphasis (`defaultAction` shortcut + semibold weight) while preserving existing save/cancel behavior. Session mode received clarity-only presentation improvements (explicit operational status chip, stronger pinned-check row affordance, consistent supporting guidance) plus restrained state animation for mode toggling.
- **blockers:** simulator/runtime sanity execution remains blocked in this environment because `CoreSimulatorService` is unavailable (`Connection invalid/refused`), so focused manual runtime acceptance is still required on a normal local simulator/device environment for character list, character detail, one editor sheet flow, and session mode.

### Batch 22 — Character templates + quick-start flow
- **status:** validated for build/test; focused runtime manual acceptance pass pending
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, attempted `xcrun simctl list devices available`
- **results:** added local-first reusable character templates without changing core character editing behavior. Introduced template domain/application/persistence path using existing character section shapes (`profile`, `characteristics/resources`, `skills`, `notes`, `equipment`, `session`) and explicit copy/apply logic. Added quick-start create flow supporting blank character or saved template. Added `Save as Template` from existing character detail flow. Added template management UI for list, lightweight preview, rename, duplicate, and delete. Preserved both accepted persistence backends by implementing template repositories for JSON (default/fallback) and SwiftData (alternative) and wiring both through `AppContainer`. Added tests for save-as-template, create-from-template distinct character identity, template rename/duplicate/delete persistence, non-shared mutable linkage on apply, and lifecycle regression stability with templates enabled, plus SwiftData template persistence parity checks.
- **blockers:** simulator/runtime sanity execution remains blocked in this environment because `CoreSimulatorService` is unavailable (`Connection invalid/refused`), so manual runtime acceptance for template flows (blank create, save-as-template, create-from-template, rename/delete) remains required on a normal local simulator/device environment.

### Batch 23 — Campaign log + character history
- **status:** validated for build/test; focused runtime manual acceptance pass pending
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`
- **results:** implemented a local character-scoped campaign history model (`CharacterHistoryEntry`) with practical entry types (`session note`, `advancement`, `injury`, `corruption/insanity`, `equipment change`, `story note`, `custom`) and optional tags metadata. Added explicit history CRUD use-cases, integrated `Campaign Log & History` into the existing character detail flow, and added quick-add session note action from character detail. Added history UI with reverse-chronological list, empty states, add/edit/delete, lightweight expandable detail rows, entry-type filter, and text search (title/body/tags). Preserved accepted persistence behavior on both paths by storing history in the existing character payload model (JSON + SwiftData). Added compatibility-safe decoding defaults for older JSON/import payloads without history fields. Added tests for history add/edit/delete persistence, per-character scoping, deletion behavior when character is deleted, duplicate/template safety (no history carry-over), and history search/filter behavior.
- **blockers:** simulator/runtime interaction is not available in this environment, so manual runtime acceptance for add/edit/delete/filter/quick-add flows remains required on a normal local simulator/device environment.

### Batch 24 — UI smoke automation + reproducible screenshots
- **status:** validated with environment-dependent simulator execution
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, `./scripts/run_ui_smoke.sh`, `./scripts/run_ui_screenshots.sh`
- **results:** added deterministic host launch hooks for UI automation (`-dh-uitesting`, `-dh-ui-reset-data`, `-dh-ui-seed-smoke`, persistence selector flags), parser unit tests, and a practical smoke/screenshot XCUITest-style flow suite in host tests covering launch/list/create/open/edit profile + section navigation entry points (characteristics/resources, skills, notes, equipment, session mode, templates manager, history, import/export menu visibility). Added canonical scripts for smoke and screenshot runs and attachment export from `.xcresult` bundles.
- **blockers:** simulator-dependent execution may fail in restricted environments without CoreSimulator availability; when simulator is unavailable, pipeline wiring is still validated by build + command-level setup but runtime UI pass must be executed on a normal local Xcode simulator setup.

### Batch 24 corrective pass — canonical UI destination configuration
- **status:** partially validated (script fix complete; runtime execution still environment-blocked)
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `./scripts/run_ui_smoke.sh`, `./scripts/run_ui_screenshots.sh`, `UI_DESTINATION=\"id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C\" ./scripts/run_ui_smoke.sh`, `UI_DESTINATION=\"id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C\" ./scripts/run_ui_screenshots.sh`
- **results:** updated both canonical UI automation scripts to remove obsolete `iPhone 16` name-based destination and use `UI_DESTINATION` with default fallback `id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C`; scripts now print the exact `xcodebuild` command and destination used.
- **blockers:** this environment still cannot execute simulator-based `xcodebuild test` due `CoreSimulatorService` unavailability plus restricted access to Xcode/SwiftPM cache/log paths (`Operation not permitted`), so end-to-end successful simulator execution could not be confirmed here.

### Batch 24 corrective pass — UI test target/scheme app-host wiring
- **status:** configuration fixed; simulator execution still blocked by environment restrictions
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, Xcode `BuildProject`, `./scripts/run_ui_smoke.sh`, `./scripts/run_ui_screenshots.sh`, `UI_DESTINATION="id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C" ./scripts/run_ui_smoke.sh`, `UI_DESTINATION="id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C" ./scripts/run_ui_screenshots.sh`
- **results:** created and wired a proper UI Testing Bundle target `DHCharListHostUITests` (product type `bundle.ui-testing`) with target application `DHCharListHost`; moved smoke/screenshot UI tests to the UI test target; added UI test target to `DHCharListHost` shared scheme test action and to `DHCharListHost.xctestplan`; updated canonical smoke/screenshot scripts to run `-only-testing:DHCharListHostUITests/...`; the previous suite-construction failure mode (`targetApplicationPath:(null)` / `targetApplicationBundleID:(null)`) is addressed at project/scheme/testplan configuration level.
- **blockers:** this Codex execution environment cannot complete simulator-based `xcodebuild test` due `CoreSimulatorService` connection invalid/refused and restricted access to Xcode/SwiftPM cache/log paths (`Operation not permitted`), so successful end-to-end simulator UI execution still requires running the same canonical commands on a normal local Xcode simulator environment.

### Batch 24 smoke corrective pass — stale blank-create scenario
- **status:** scenario fix implemented; simulator execution still environment-blocked
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `./scripts/run_ui_smoke.sh`, `./scripts/run_ui_screenshots.sh`
- **results:** updated smoke test blank-create selector from a stale user-facing label lookup to a stable accessibility identifier path aligned with current Create Character quick-start UI; added `.accessibilityIdentifier("quickstart.blank-character")` on the blank character quick-start control and updated smoke test to tap that identifier with a row-control fallback (`button` then `otherElement`) for robust list-row rendering.
- **blockers:** canonical UI script execution remains blocked in this Codex environment by CoreSimulator/cache permissions (`CoreSimulatorService` invalid/refused and `Operation not permitted` under `~/Library/...`), so end-to-end simulator pass could not be completed here.

### Batch 25 — Practical CI integration for validated local workflow
- **status:** validated for repository wiring; live CI runtime remains external
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `./scripts/run_xcode_coverage.sh`, `./scripts/check_coverage_policy.sh`, `./scripts/run_ui_smoke.sh`, `./scripts/run_ui_screenshots.sh`, workflow YAML parse validation (`python3` + `yaml.safe_load` for `.github/workflows/ci.yml` and `.github/workflows/ui-tests.yml`)
- **results:** staged CI is now wired to canonical repository commands without product/runtime scope changes. Required push/PR workflow (`.github/workflows/ci.yml`) now runs a fast SwiftPM job (`swift build`, `swift test`) and a macOS/Xcode validation job (host app build, coverage capture script, coverage policy gate), with practical coverage artifact upload (`.xcresult`, logs, `xccov` summary/JSON, normalized metrics JSON). Optional heavier UI automation remains a separate manual workflow (`.github/workflows/ui-tests.yml`) and now reuses the canonical UI scripts directly, publishing full smoke/screenshot artifact directories. README CI documentation now explicitly states required vs optional jobs, artifacts, local-to-CI command mapping, and intentionally manual items.
- **blockers:** actual GitHub-hosted workflow execution cannot be performed from this local Codex session; final runtime confirmation of GitHub runner behavior depends on running the workflows in GitHub Actions.

## 2026-03-09

### Batch 26 — Live GitHub Actions bring-up and stabilization
- **status:** blocked (environment-auth limitation in this session)
- **checks run:** workflow/script inspection (`.github/workflows/ci.yml`, `.github/workflows/ui-tests.yml`, `scripts/run_xcode_coverage.sh`, `scripts/check_coverage_policy.sh`, `scripts/run_ui_smoke.sh`, `scripts/run_ui_screenshots.sh`), Git remote connectivity (`git ls-remote --heads origin`), GitHub API probe without auth (`curl https://api.github.com/repos/artemenko-a-a/DH_charlist/actions/workflows`)
- **results:** required and optional workflows remain structurally coherent for GitHub-hosted macOS execution and still map to the accepted canonical local commands (`swift build`, `swift test`, coverage capture + gate, UI smoke/screenshots). Artifact upload paths and diagnostic log/result-bundle outputs are already wired. However, from this session, live GitHub-hosted run bring-up cannot be completed because repository API access is unavailable (private-repo API returns `404` without auth) and `gh` is not installed/authenticated, so run dispatch/status/log retrieval cannot be performed.

### Batch 27 — Live optional UI workflow bring-up and stabilization
- **status:** validated
- **checks run:** `gh auth status`, `gh workflow view ui-tests.yml`, `gh run list --workflow ui-tests.yml --limit 5`, hosted smoke run inspection (`gh run view 22844748423`, `gh run view 22844748423 --log`), hosted smoke dispatch/reruns (`gh workflow run ui-tests.yml -f test_target=smoke --ref main`), hosted screenshot dispatch (`gh workflow run ui-tests.yml -f test_target=screenshots --ref main`), hosted artifact downloads (`gh run download 22847283186 -n ui-smoke-artifacts ...`, `gh run download 22848408585 -n ui-screenshot-artifacts ...`), `swift build --build-path /tmp/dh_charlist-b27-build`, `swift test --build-path /tmp/dh_charlist-b27-build`, `bash -n scripts/run_ui_smoke.sh scripts/run_ui_screenshots.sh`
- **results:** the optional GitHub Actions UI workflow was exercised for real on GitHub-hosted macOS runners. The first live smoke attempts exposed a hosted-runner stall after simulator boot and `xctrunner` launch handoff; artifact diagnostics from the canceled run showed the session reaching simulator connection and runner launch but not progressing to test output. A minimal workflow-only fix stabilized the hosted path without touching product/runtime behavior: pin `DEVELOPER_DIR` to Xcode 16.4, wait for `simctl bootstatus -b`, and add bounded step/job timeouts so manual runs remain truthful. After that change, smoke completed green on hosted runners in run `22848098651` (`7m58s`) and screenshots completed green in run `22848408585` (`17m17s`), with screenshot attachments exported and uploaded as artifacts.
- **blockers:** none for the optional workflow after the workflow-only fix; the workflow remains intentionally manual by design, not required.
- **blockers:** missing GitHub API authentication in this environment (no `GH_TOKEN`/`GITHUB_TOKEN`, `gh` unavailable), which prevents executing and validating live GitHub-hosted runs from this session.

### Batch 26 corrective pass — first live required CI failure triage/fix verification
- **status:** validated (first failure resolved; no new required-workflow blocker observed)
- **first failing live run inspected:** `CI` run #1 (`https://github.com/artemenko-a-a/DH_charlist/actions/runs/22819505268`)
- **failing job/step/error:** job `Xcode build & analyze (DHCharListHost)` → step `Xcode build` failed with `xcodebuild: error: ... project ... is in a future Xcode project file format (77)` on runner image `macos-14-arm64` using `/Applications/Xcode_15.4.app`
- **cause classification:** runner environment mismatch + workflow Xcode version assumption mismatch (project format requires newer Xcode than runner image had)
- **minimal corrective fix in accepted pipeline state:** required workflow is now pinned to `runs-on: macos-15` for required jobs (newer Xcode image compatible with project format), preserving existing staged CI design and script usage
- **checks run:** `gh run view 22819505268` (jobs/steps/log triage), `gh run rerun 22843709355`, GitHub Actions API jobs/status checks for rerun attempt 2, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- **results:** rerun of required workflow on current accepted CI config completed green on both required jobs: `Fast validation (SwiftPM)` and `Xcode host + coverage gate`; coverage pipeline step, coverage policy gate step, and coverage artifact upload step all passed in live GitHub-hosted execution.
- **blockers:** none observed for this first-failure corrective pass; optional UI workflow remains separate/manual by design and was not promoted to required.

### Batch 28 — TestFlight / distribution bring-up
- **status:** validated as archive-ready / TestFlight-prepared
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS Simulator' build`, `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Release -destination 'generic/platform=iOS' -showBuildSettings`, `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`, `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Release -destination 'generic/platform=iOS' archive -archivePath /tmp/DHCharListHost-Batch28.xcarchive CODE_SIGNING_ALLOWED=NO`, `plutil -p /tmp/DHCharListHost-Batch28.xcarchive/Info.plist`, `xcodebuild -exportArchive -archivePath /tmp/DHCharListHost-Batch28.xcarchive -exportPath /tmp/DHCharListHost-Batch28-export -exportOptionsPlist /tmp/DHCharListHost-Batch28-exportOptions.plist`
- **results:** the host project is structurally ready for distribution work without product/runtime changes. Release metadata is coherent (`MARKETING_VERSION=1.0`, `CURRENT_PROJECT_VERSION=1`, display name `DH CharList`, deployment target iOS 17.6, Automatic signing with no committed team). A normal Xcode simulator build succeeded, an unsigned generic iOS Release build succeeded, and an unsigned generic iOS archive succeeded. Archive metadata confirms the exact remaining gap: `CFBundleIdentifier` is still the placeholder `com.example.DHCharListHost`, and both `SigningIdentity` and `Team` are empty in the archive. Export probing with `method=app-store-connect` failed truthfully with `exportArchive No Team Found in Archive`, isolating the remaining work to Apple-account-controlled signing/bundle-id/App Store Connect setup rather than archive structure. Added distribution documentation plus an example export-options plist template so the repo now has a practical manual finish line for TestFlight.
- **blockers:** real TestFlight upload still requires manual Apple Developer configuration outside repository control: replace placeholder bundle identifiers, select a real Apple team/signing identity, create/configure the App Store Connect app record, and run a signed archive/export/upload with local credentials or an App Store Connect auth key.

### Batch 29 — Rules-aware quick mechanics helpers
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS Simulator' build`, `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'id=F5CF78D3-E801-4B76-B69D-04FB1CED7680' -resultBundlePath /tmp/dh-b29-quick-mechanics-rerun-3.xcresult -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testQuickMechanicsHelpersAcrossCharacteristicSkillAndSessionFlows`, `./scripts/run_ui_smoke.sh`
- **results:** added a transparent quick mechanics builder on top of existing character data without expanding into a rules engine. Users can now open quick characteristic checks from `Characteristics & Resources`, quick skill checks from `Skills`, and a session-oriented entry point from `Session Mode`. The helper shows source, base value, derived bonus, training contribution when relevant, applied modifier, and final target; preset modifiers (`+30` through `-30`) and custom signed input are both supported, and current Session Mode temporary modifiers can be reused directly in the helper. Calculation logic stays explicit and reversible by using current characteristic values plus existing skill training modifiers only. Added package tests for characteristic checks, skill checks, modifier presets, and `DerivedValueCalculator` consistency. Added a focused simulator UI sanity pass covering characteristic helper entry, skill helper entry, preset/custom modifier application, and session-mode access; the helper breakdown required scrolling in the compact sheet, so the UI test now reveals the final target row before asserting. The existing canonical smoke script remains unchanged and still passes, so accepted baseline flows did not regress.
- **blockers:** none for the implemented app path; focused manual acceptance remains useful for final visual/runtime review on device or simulator.

### Batch 30 — Combat workspace + encounter-speed helpers
- **status:** validated
- **checks run:** `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`, `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS Simulator' build`, `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'id=F5CF78D3-E801-4B76-B69D-04FB1CED7680' -resultBundlePath /tmp/dh-b30-combat-workspace.xcresult -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testCombatWorkspaceActivePlayFlow`, `./scripts/run_ui_smoke.sh`
- **results:** evolved the accepted `Session Mode` flow into a more practical combat workspace without introducing a combat engine. The workspace now prioritizes live-play values (current wounds, fatigue, current fate), active-weapon focus, movement reference, pinned checks, temporary modifiers, quick mechanics shortcuts, and short combat condition notes in one character-scoped screen. Active weapon selection reuses existing weapon data, persists as explicit session state, and safely clears if the referenced weapon is removed later. Combat conditions are lightweight local notes, not a rules-driven status engine. Added package tests for persistence compatibility and character scoping of the new session fields (`activeWeaponID`, `combatConditions`), and added a focused simulator UI test covering weapon selection, workspace quick adjustments, quick mechanics access, combat-condition entry, and continued pinned-check/modifier usability. The canonical smoke script still passes, so accepted baseline flows remain intact.
- **blockers:** none for the implemented app path; focused manual acceptance remains useful for visual/ergonomic review on device or simulator.
