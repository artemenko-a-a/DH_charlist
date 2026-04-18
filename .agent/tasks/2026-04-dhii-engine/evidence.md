# Evidence Report

## Task
- ID: 2026-04-dhii-engine
- Title: DHII Engine architecture freeze with Tasks 01-08 creation foundations, persistence seam, and engine-backed flow

## What was implemented
- Repo architecture, DHII engine target state, phased roadmap, and ordered task decomposition are documented in [`Docs/dhii-engine-roadmap.md`](/Users/andrey_artemenko/repos/DH_charlist/Docs/dhii-engine-roadmap.md).
- Tasks 01-03 established canonical DHII catalogs and explainable previews in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift):
  - six core home worlds
  - seven core backgrounds
  - eight core roles
  - alias normalization
  - rulebook-backed summaries and compatibility diagnostics
- Task 03 also added deterministic aptitude composition and bounded progression integration in:
  - [`Sources/DHCharList/Rules/XPProgression.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/XPProgression.swift)
  - [`Sources/DHCharList/Rules/ProgressionRegistries.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/ProgressionRegistries.swift)
  - [`Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift)
- Task 04 introduced the typed in-memory creation aggregate in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift):
  - canonical selections
  - explicit choice-slot state
  - legacy fallback aptitude separation
  - stale-choice pruning on upstream changes
- Task 05 introduced typed creation-time characteristic generation in:
  - [`Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift)
  - supports standard DHII random generation (`2d10 + 20`, one reroll, home-world modifiers)
  - supports standard point allocation (`25` base, `60` points, `40` cap)
  - keeps transient `Influence` explicit
- Task 06 introduced bounded starting-package projection in [`Sources/DHCharList/Rules/CharacterCreationProjection.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationProjection.swift), yielding a safe legacy `Character` snapshot plus transient `Influence` from a fully resolved creation draft.
- Task 07 introduced additive persisted engine state in:
  - [`Sources/DHCharList/Domain/CharacterEngineState.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Domain/CharacterEngineState.swift)
  - [`Sources/DHCharList/Domain/Character.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Domain/Character.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationProjection.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationProjection.swift)
  - [`Sources/DHCharList/Infrastructure/ImportExport/CharacterJSONImportExportService.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Infrastructure/ImportExport/CharacterJSONImportExportService.swift)
- Persisted engine state now stores, in additive form:
  - canonical home world/background/role ids
  - supported choice-slot selections
  - starting wounds/fate rolls
  - legacy fallback aptitudes
  - characteristic-generation provenance and point-allocation state
- Draft restoration now prefers persisted engine state when available and sanitizes stale or unknown persisted values before rebuilding the typed draft.
- Export/import now remains backward-compatible:
  - schema `1` imports still load
  - schema `2` exports round-trip `dhiiEngineState`
- Task 08 introduced the staged DHII Engine-backed create/edit flow in:
  - [`Sources/DHCharList/Presentation/Features/CharacterCreation/DHIICreationFlowScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/CharacterCreation/DHIICreationFlowScreen.swift)
  - [`Sources/DHCharList/Presentation/Features/CharacterList/CharacterListScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/CharacterList/CharacterListScreen.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationProjection.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationProjection.swift)
  - [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift)
- The new flow now provides:
  - guided staged creation for supported canonical origin choices, package slots, and characteristic generation
  - safe edit/re-entry for engine-backed characters using persisted `dhiiEngineState`
  - reprojection of existing engine-backed characters while preserving identity and supported player-authored deltas
  - explicit redirection away from contradictory manual origin editing in the legacy profile screen

## Test files added or expanded
- [`Tests/DHCharListTests/CharacterCreationEngineTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/CharacterCreationEngineTests.swift)
- [`Tests/DHCharListTests/DHCharListTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/DHCharListTests.swift)
- [`DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`](/Users/andrey_artemenko/repos/DH_charlist/DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift)
- Existing web regression tests remained part of the validation gate

## Commands actually run
- `swift test --filter CharacterCreationEngineTests`
- `swift test --filter DHCharListTests`
- `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'id=A91DD7E0-C2BD-4919-8398-B12E5F9748BD' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testGuidedDHIIFlowCreatesEngineBackedCharacterAndAllowsReentry`
- `swift build`
- `swift test`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `cd web && npm run build`
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `make ci`

## Results
- `swift test --filter CharacterCreationEngineTests`: passed
- `swift test --filter DHCharListTests`: passed
- targeted `xcodebuild` guided-flow smoke: passed
- `swift build`: passed
- `swift test`: passed (`202` tests)
- `cd web && npm test`: passed (`17` tests)
- `cd web && npm run typecheck`: passed
- `cd web && npm run build`: passed
- `make fmt`: passed (`no-op fallback; no repository formatter configured`)
- `make lint`: passed (`no-op fallback; no repository linter configured`)
- `make typecheck`: passed
- `make test`: passed
- `make ci`: passed
- Coverage policy: passed
- Coverage highlights from the final `make ci` run:
  - package surface coverage: `25.94%`
  - Domain: `96.91%`
  - Rules: `94.32%`

## Rules / logic evidence
- Canonical engine catalogs cover the full DHII core sets already targeted by the roadmap:
  - home worlds: `Feral World`, `Forge World`, `Highborn`, `Hive World`, `Shrine World`, `Voidborn`
  - backgrounds: `Adeptus Administratum`, `Adeptus Arbites`, `Adeptus Astra Telepathica`, `Adeptus Mechanicus`, `Adeptus Ministorum`, `Imperial Guard`, `Outcast`
  - roles: `Assassin`, `Chirurgeon`, `Desperado`, `Hierophant`, `Mystic`, `Sage`, `Seeker`, `Warrior`
- Explainable aptitude composition distinguishes:
  - fixed package aptitudes that can be derived safely now
  - unresolved choice-slots that must stay explicit
  - leftover legacy fallback aptitudes that must not be silently reinterpreted
- Characteristic generation is typed and rulebook-backed for the supported standard modes only.
- Starting-package projection refuses unresolved or unsupported states instead of guessing.
- Persisted creation-state restoration is sanitized; stale/unknown canonical ids do not get blindly trusted as valid DHII state.
- Engine-backed projection now persists its bounded creation truth explicitly, instead of forcing later reloads to rely only on ambiguous legacy `Profile` text.
- Engine-backed create/edit flows now route supported creation decisions through the typed draft and projection layers instead of writing origin truth directly into raw legacy profile fields.
- Reprojection of existing engine-backed characters requires persisted engine state and preserves supported player-authored deltas instead of flattening them away.

## Data safety evidence
- Existing saved characters still decode if `dhiiEngineState` is absent.
- Additive persistence does not rewrite legacy freeform profile fields into typed replacements.
- Import/export remains backward-compatible for legacy schema `1`.
- Export now emits schema `2`, making the migration explicit instead of silent.
- `Character` codable round-trip preserves `dhiiEngineState` when present and defaults it to `nil` when absent.
- Projected engine-backed characters round-trip without losing persisted creation state.
- No silent destructive migration path was introduced.
- Engine-backed edit flow preserves character identity while refreshing the projected snapshot from persisted creation truth.

## Runtime / UI evidence
- Existing profile flow remains intact; engine-backed characters now get explicit guidance to revise origin selections through the DHII creation flow.
- Guided DHII creation can create an engine-backed character, save it, reopen it, and re-enter edit mode through the host smoke suite.
- Host/UI regression coverage stayed green through the final `make ci` run, including the long smoke suite.
- No new contradictory user-visible state was observed in the bounded flows covered by the regression suite.
- Manual screenshot review was not performed.

## Confidence split
- Logic confidence: high
- Runtime confidence: high
- UI confidence: medium-high
- Real-device confidence: low

## Not verified in this environment
- Real-device behavior
- Manual visual review of the engine-backed creation/edit flow
- Progression/dependency hardening beyond the currently bounded helpers

## Residual issues
- `Influence` still is not a first-class persisted field on the public `Character` snapshot.
- Background and role package automation outside the currently supported bounded projection surface remains unfinished.
- The staged flow is intentionally bounded to supported creation mechanics; unsupported package effects still remain explicit rather than automated.
- Web still does not consume the new creation engine seam directly.

## Recommended verdict
- accepted_with_conditions

## Recommended next step
- Harden progression and dependency evaluation against persisted engine state, then decide whether the longer-term follow-up is first-class `Influence`, broader package automation, or explicit web limitation.
